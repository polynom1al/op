#
# File: OP/Series.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
use OP;

require Math::Spline;

use OP::Enum::Consol;
use OP::Enum::Inter;
use OP::Enum::StatType;

use Parse::RPN;

create "OP::Series" => {
  #
  # Inheritance
  #
  # __BASE__    => "OP::Hash",
  __useDbi => false,

  name => OP::Str->assert(
    ::optional(),
  ),

  #
  # x axis options
  #
  xKey      => OP::Str->assert(
    ::default("timestamp"),
  ), # key to use for x axis

  xTickSize => OP::Double->assert(
    ::default(60),
  ), # num seconds typically

  xMajorTickSize => OP::Double->assert(), # num seconds typically

  xConsolidator => OP::Int->assert(
    OP::Enum::Consol::Average,
    OP::Enum::Consol::Median,
    OP::Enum::Consol::Min,
    OP::Enum::Consol::Max,
    OP::Enum::Consol::Sum,
    OP::Enum::Consol::First,
    OP::Enum::Consol::Last,
    OP::Enum::Consol::Random,
    ::default( OP::Enum::Consol::Average )
  ),

  xMin      => OP::Double->assert(), # ie start time

  xMax      => OP::Double->assert(), # ie end time

  #
  # y axis options
  #
  yKey      => OP::Str->assert(
    ::default("value"),
  ),  # key to use for y axis

  yRpn      => OP::Str->assert(),  # optional rpn expression

  yType     => OP::Int->assert(
    OP::Enum::StatType::Gauge,
    OP::Enum::StatType::Counter,
    OP::Enum::StatType::Derivative,
    ::default( OP::Enum::StatType::Gauge )
  ),

  yInterpolate => OP::Int->assert(
    OP::Enum::Inter::Linear,
    OP::Enum::Inter::Spline,
    OP::Enum::Inter::Constant,
    OP::Enum::Inter::Undefined,
    OP::Enum::Inter::None,
    ::default(OP::Enum::Inter::Linear)
  ),

  #
  # Reset all consolidation and cooking
  #
  clearHash => sub($) {
    my $self = shift;

    delete $self->{_hash};

    delete $self->{_consol};
  },


  #
  # Add a raw object
  #
  addObject => sub($$) {
    my $self = shift;
    my $object = shift;

    $self->_raw()->push($object);
  },


  #
  #
  #
  cooked => sub($) {
    my $self = shift;
    my $cooked = OP::Hash->new();

    my $step  = $self->xTickSize();
    my $start = $self->xMin();
    my $end   = $self->xMax();

    my $consKeys = $self->_consolidated()->keys();

    #
    # Extrapolation would happen here
    #
    $start = $consKeys->first()
      if $consKeys->first() > $start;

    $end = $consKeys->last()
      if $consKeys->last() < $end;

    my $x = $start;

    #
    # No Interpolation:
    #
    if ( $self->yInterpolate() == OP::Enum::Inter::None ) {
      $consKeys->each( sub {
        my $x = $_;
	my $y = $self->_consolidated()->{$_};

        return if $x < $start;
        return if $x > $end;

        #
        # Apply the RPN expression, if any
        #
        if ( $self->yRpn() ) {
          $y = rpn(join ',', $y, $self->yRpn());
          my $error = rpn_error();
          die $error if $error;
        }

        $cooked->{$x} = $y;
      } );

      return $cooked;
    }

    #
    # include raw datapoints!
    #
    if (
      $self->yInterpolate() == OP::Enum::Inter::Constant
        || $self->yInterpolate() == OP::Enum::Inter::None
    ) {
      $self->_prepped()->keys()->each( sub {
        $cooked->{$_} ||= OP::Array->new();

        $cooked->{$_} = $self->_prepped()->{$_};
      } );
    }

    #
    # Interpolation:
    #
    until ( $x > $end ) {
      my $y = $self->yForX($x);

      if ( defined $y ) {
        #
        # Apply the RPN expression, if any
        #
        if ( $self->yRpn() ) {
          $y = rpn(join ',', $y, $self->yRpn());
          my $error = rpn_error();
          die $error if $error;
        }

        $cooked->{$x} = $y
      } elsif (
        $self->yInterpolate() == OP::Enum::Inter::Undefined
      ) {
        $cooked->{$x} = undef;
      }

      $x += $step;
    }

    #
    #
    #
    if ( $self->yType() != OP::Enum::StatType::Gauge ) {
      $cooked = $self->_counterToGauge($cooked);
    }

    if ( $self->xMajorTickSize() > 0 ) {
      $cooked = $self->_rolling($cooked);
    }

    return $cooked;
  },


  #
  # array of all objects which have been added
  #
  _raw => sub($) {
    my $self = shift;

    $self->{_raw} ||= OP::Array->new();

    return $self->{_raw};
  },


  #
  # Consolidate the received array into a single value
  # as per self's xConsolidator constant
  #
  _consolidate => sub($$) {
    my $self = shift;
    my $array = shift;

    my $fn = $self->xConsolidator();

    if ( $fn == OP::Enum::Consol::First ) {
      return $array->first();
    } elsif ( $fn == OP::Enum::Consol::Last ) {
      return $array->last();
    } elsif ( $fn == OP::Enum::Consol::Random ) {
      return $array->rand();
    } elsif ( $fn == OP::Enum::Consol::Sum ) {
      return $array->sum();
    } elsif ( $fn == OP::Enum::Consol::Max ) {
      return $array->max();
    } elsif ( $fn == OP::Enum::Consol::Min ) {
      return $array->min();
    } elsif ( $fn == OP::Enum::Consol::Median ) {
      return $array->median();
    } else {
      return $array->average();
    }
  },


  #
  # First consolidation pass:
  #
  # Process the object array into a Hash of prepared data.
  #
  # Consolidates duplicate samples (samples with overlapping X value)
  #
  # Does not account for desired tick spacing (xTickSize). Consolidation
  # of interpolated data happens later.
  #
  _prepped => sub($) {
    my $self = shift;

    return $self->{_hash} if $self->{_hash};
    
    my $hash = OP::Hash->new({ });

    $self->_raw()->each( sub {
      my $object = $_;

      my $key = $object->{ $self->xKey() };
      my $value = $object->{ $self->yKey() };

      $hash->{$key} ||= OP::Array->new();
      $hash->{$key}->push($value);
    } );

    $hash->keys()->each( sub {
      $hash->{$_} = $self->_consolidate($hash->{$_});
    } );

    $self->{_hash} = $hash;

    return $hash;
  },


  #
  # get the Y value for X, interpolating if needed
  #
  yForX => sub() {
    my $self = shift;
    my $xKey = shift;
    my $hash = shift || $self->_consolidated();

    return $hash->{$xKey} if exists $hash->{$xKey};

    if ( $self->yInterpolate() == OP::Enum::Inter::Undefined ) {
      return undef;
    }

    if ( $self->yInterpolate() == OP::Enum::Inter::None ) {
      #
      # Caller needs to handle undef appropriately
      #
      return undef;
    }

    my $keys = $hash->keys();

    if ( $self->yInterpolate() == OP::Enum::Inter::Spline ) {
      $self->{_spline} ||= Math::Spline->new( $keys, $hash->values() );

      return $self->{_spline}->evaluate($xKey);
    }

    my $i = 0;

    for my $key ( @{ $keys } ) {
      # die "index $i is out of range 0.." . ($keys->size()-1)
        # if $i == $keys->size();

      last if $i == $keys->size() - 1;

      next if $xKey <= $keys->get($i+1);

      $i++;
    }

    my $lower = $keys->get( $i );
    my $upper = $keys->get( $i + 1 );

    return $self->_interp(
      $xKey, $lower, $upper, $hash->{$lower}, $hash->{$upper}
    );
  },


  #
  # Props to Tie::Hash::Interpolate
  #
  _interp => sub($$$$$$) {
    my $self = shift;
    my ($x, $x1, $x2, $y1, $y2) = @_;

    if ( $self->yInterpolate() == OP::Enum::Inter::Linear ) {
      my $slope     = ($y2 - $y1) / ($x2 - $x1);
      my $intercept = $y2 - ($slope * $x2);
      return $slope * $x + $intercept;
    } else { # Constant
      #
      # Edge-based values; assume constant until change
      #
      return $y1;
    }
  },


  #
  # Second consolidation pass:
  #
  # Evenly apply "tick spacing" to X values, and consolidate duplicate
  # samples (samples with overlapping X value)
  #
  _consolidated => sub($) {
    my $self = shift;

    return $self->{_consol} if $self->{_consol};

    my $hash = $self->_prepped();

    my $step  = $self->xTickSize();
    my $start = $self->xMin();
    my $end   = $self->xMax();

    my $x = $start;

    my $keys = $hash->keys();
    $keys->shift();

    my $consol = OP::Hash->new();

    until ( $x > $end + $step ) {
      $consol->{$x} ||= OP::Array->new();

      while(1){
        last if $keys->isEmpty();

        if ( $x >= $keys->first() ) {
          $consol->{$x}->push( $hash->{$keys->shift()} );
        } else {
          last;
        }
      }

      delete $consol->{$x} if $consol->{$x}->isEmpty();
        
      $x += $step;
    }

    $consol->keys()->each( sub {
      $consol->{$_} = $self->_consolidate($consol->{$_});
    } );

    #
    # include raw datapoints!
    #
    if (
      $self->yInterpolate() == OP::Enum::Inter::Constant
    ) {
      $self->_prepped()->keys()->each( sub {
        $consol->{$_} ||= OP::Array->new();

        $consol->{$_} = $self->_prepped()->{$_};
      } );
    }

    $self->{_consol} = $consol;

    return $consol;
  },


  #
  # Final consolidation pass:
  #
  # Apply a "major tick" to get a rolling average of X values
  #
  _rolling => sub($) {
    my $self = shift;
    my $hash = shift;

    my $step  = $self->xMajorTickSize();
    my $start = $self->xMin();
    my $end   = $self->xMax();

    my $x = $start;

    my $keys = $hash->keys();

    my $consol = OP::Hash->new();

    until ( $x > $end ) {
      $consol->{$x} = OP::Array->new();

      while(1){
        last if $keys->isEmpty();

        if ( $x >= $keys->first() ) {
          $consol->{$x}->push( $hash->{$keys->shift()} );
        } else {
          last;
        }
      }

      delete $consol->{$x} if $consol->{$x}->isEmpty();
        
      $x += $step;
    }

    $consol->keys()->each( sub {
      $consol->{$_} = $self->_consolidate($consol->{$_});
    } );

    $self->{_consol} = $consol;

    return $consol;
  },


  #
  #
  #
  _counterToGauge => sub($$) {
    my $self = shift;
    my $cooked = shift;

    my $previousX;
    my $previousY;

    my $burned = OP::Hash->new({ });

    $cooked->keys()->each( sub {
      my $x = $_;
      my $y = $cooked->{$_};

      if ( defined $previousY ) {
        if ( $self->yType() == OP::Enum::StatType::Counter ) {
          if ( $previousY > $y ) { # Counter wrapped or reset
            undef $previousX;
            undef $previousY;

            return;
          }
        }

        my $xDelta = $x - $previousX;
        my $yDelta = $y - $previousY;

        my $yRate = sprintf('%.2f', $yDelta / $xDelta);

        $burned->{$x} = $yRate;
      }

      $previousX = $x;
      $previousY = $y;
    } );

    if ( $self->yInterpolate() == OP::Enum::Inter::None ) {
      #
      # This will leave undefined regions alone
      #
      return $burned;
    }

    #
    # Interpolate in any gaps left by counter wrap/reset
    #
    my $step  = $self->xTickSize();
    my $start = $self->xMin();
    my $end   = $self->xMax();

    my $x = $start;

    delete $self->{_spline};

    until ( $x > $end ) {
      my $y = $self->yForX($x,$burned);

      if ( defined $y ) {
        $burned->{$x} = $y;
      } elsif (
        $self->yInterpolate() == OP::Enum::Inter::Undefined
      ) {
        $burned->{$x} = undef;
      }

      $x += $step;
    }

    return $burned;
  }
};

=pod

=head1 NAME

OP::Series

=head1 DESCRIPTION

Generate consolidated, interpolated series data from an array of
objects.

=head1 SYNOPSIS

  use OP::Series;

  my $series = OP::Series->new();

=head1 INSTANCE METHODS

=head2 Axis Options

=over 4

=item * setXKey($xKey), setYKey($yKey)

Define which object keys to use for X and Y axis:

  $series->setXKey("timestamp");
  $series->setYKey("value");

=back

=head2 X Axis Options

=over 4

=item * setXMin($xMin), setXMax($xMax)

Confine the received data to a range specified by xMin and xMax.

Set X axis opts (time opts, in this case):

  $series->setXMin(1218508949);
  $series->setXMax(1218508969);

=item * setXTickSize($size)

Specify the desired step interval between datapoints on the X axis.

The unit of measurement would be the same as the value being used for
the axis (so, seconds if plotting seconds, widgets if plotting widgets).

  $series->setXTickSize(1); # 1 Second

=item * setXMajorTickSize($size)

Apply a "moving average" to the data after
expanding base ticks. (Optional/Experimental)

  $series->setXMajorTickSize(60); # 1 Minute

=item * setXConsolidator($const)

Specify a function to use for consolidation of overlapping values. Valid
arguments are:

  OP::Enum::Consol::Average # Average value
  OP::Enum::Consol::Median  # Median value
  OP::Enum::Consol::Min     # Minimum value
  OP::Enum::Consol::Max     # Maximum value
  OP::Enum::Consol::Sum     # Sum of values
  OP::Enum::Consol::First   # First value seen
  OP::Enum::Consol::Last    # Last value seen
  OP::Enum::Consol::Random  # Random value

This is an optional argument, and defaults to Average.

  $series->setXConsolidator(
    OP::Enum::Consol::Median
  );

=back

=head2 Y Axis Options

=over 4

=item * setYInterpolate($const)

Optional, set interpolation type. Valid args are:

  OP::Enum::Inter::Linear     # Straight Line
  OP::Enum::Inter::Spline     # Cubic Spline
  OP::Enum::Inter::Constant   # Last Known
  OP::Enum::Inter::Undefined  # Unknowns are undef
  OP::Enum::Inter::None       # No Interpolation

Defaults to Linear.

  $series->setYInterpolate(OP::Enum::Inter::Spline);

=item * setYRpn($rpnStr)

Optional, supply an RPN expression

  $series->setYRpn("-1,*"); # Inverted axis

=item * setYType($const)

Optional, supply statistic type.

Derivative is like Counter but permits
negative values (rate of change data)

Valid arguments are:

  OP::Enum::StatType::Gauge
  OP::Enum::StatType::Counter
  OP::Enum::StatType::Derivative

Defaults to Gauge.

  $series->setYType(OP::Enum::StatType::Counter);

=back

=head2 Processing Data

=over 4

=item * addObject($object)

Add an object to the raw data set. The objects don't need to be blessed,
they just need to contain similar attributes:

  $series->addObject({
    timestamp => 1218508949,
    value => 99.1
  });

  $series->addObject({
    timestamp => 1218508969,
    value => 99.8
  });

  ...

=item * cooked()

Generate an L<OP::Hash> object, containing consolidated, interpolated,
unsorted associative rows:

  ...

  for ( @objects ) {
    $series->addObject($_);
  }

  my $data = $series->cooked(); # Returns an OP::Hash

  # { X => Y, ... }
  #
  # This example has been dealing with time series data
  # (X is time) and the hash will look like:
  #
  # { 
  #   timestamp => value,
  #   timestamp => value,
  #   ...
  # }

  #
  # Access the processed series data as a normal Perl hashref,
  # or with any OP::Hash instance method:
  #
  $data->each( sub{
    print "at unix time $_, value was $data->{$_}\n";
  } );

=item * clearHash()

Resets all internal data structures to a pre-cooked state.

  ...

  my $set1 = $series->cooked();

  $series->clearHash();

  ...

  my $set2 = $series->cooked();

=back

=head1 SEE ALSO

L<Parse::RPN>, L<Math::Spline>, L<Math::VecStat>

L<OP::Class>, L<OP::Array>, L<OP::Hash>

Inspired by L<Tie::Hash::Interpolate>

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Series.pm#2 $

=cut
