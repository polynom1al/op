#
# File: OP/SeriesChart.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
use OP;

use OP::Enum::Inter;

use Image::Magick;
use Time::HiRes;

create "OP::SeriesChart" => {
  yMin => OP::Int->assert(
    ::optional(),
  ),

  yMax => OP::Int->assert(
    ::optional(),
  ),

  width => OP::Int->assert(
    ::default(320),
  ),

  height => OP::Int->assert(
    ::default(240),
  ),

  colors => OP::Array->assert(
    OP::Array->assert(
      OP::Int->assert()
    ),
  ),

  bgColor => OP::Array->assert(
    OP::Int->assert(),
  ),

  gridColor => OP::Array->assert(
    OP::Float->assert(),
  ),

  unitColor => OP::Array->assert(
    OP::Float->assert(),
  ),

  stacked => OP::Int->assert(
    true, false,
    ::default(true),
  ),

  addSeries => sub($$) {
    my $self = shift;
    my $series = shift;

    $self->{_series} ||= OP::Array->new();
    $self->{_xMins}  ||= OP::Array->new();
    $self->{_xMaxes} ||= OP::Array->new();
    $self->{_yMins}  ||= OP::Array->new();
    $self->{_yMeds}  ||= OP::Array->new();
    $self->{_yMaxes} ||= OP::Array->new();

    my $data = $series->cooked();

    my $keys = $data->keys();
    my $values = $data->values();

    $self->{_series}->push($series);
    $self->{_xMins}->push($keys->min());
    $self->{_xMaxes}->push($keys->max());
    $self->{_yMins}->push($values->min());
    $self->{_yMeds}->push($values->median());
    $self->{_yMaxes}->push($values->max());
  },

  xMin => sub($) {
    my $self = shift;

    return if !$self->{_xMins};

    return $self->{_xMins}->min();
  },

  xMax => sub($) {
    my $self = shift;

    return if !$self->{_xMaxes};

    return $self->{_xMaxes}->max();
  },

  _yMin => sub($) {
    my $self = shift;

    return if !$self->{_yMins};

    return defined($self->{yMin})
      ? $self->{yMin}
      : $self->{_yMins}->min();
  },

  _yMed => sub($) {
    my $self = shift;

    return if !$self->{_yMeds};

    return $self->{_yMeds}->median();
  },

  _yMax => sub($) {
    my $self = shift;

    my $yMax;
    if ( $self->{yMax} ) {
      $yMax = $self->{yMax}
    } else {
      if ( $self->stacked() ) {
        $yMax = $self->{_yMaxes}->sum() * .85;
      } else {
        $yMax = $self->{_yMaxes}->max();
      }
    }

    return $yMax;
  },

  xValueToCoord => sub($$) {
    my $self = shift;
    my $x = shift;

    my $xFloor  = $self->xMin();
    my $xCeil   = $self->xMax();

    my $yFloor = $self->xcFloor();
    my $yCeil = $self->width()-1;

    if ( $xCeil - $xFloor == 0 ) {
      die "Insufficient datapoints to complete series";
    }

    return $self->xcFloor()
      # + ( int(($yFloor+($yCeil-$yFloor))
      + ( int(($yCeil-$yFloor)
      * ($x-$xFloor)/($xCeil-$xFloor)) );
  },

  yValueToCoord => sub($$) {
    my $self = shift;
    my $y = shift;

    my $xFloor  = $self->_yMin();
    my $xCeil   = $self->_yMax();

    my $yFloor = 0;
    my $yCeil = $self->ycCeil();

    if ( $xCeil - $xFloor == 0 ) {
      die "XMaxes Size ". $self->{_xMaxes}->size()
        ." Ceil $xCeil - Floor $xFloor == 0 (weird)";
    }

    return $yCeil - int(($yFloor+($yCeil-$yFloor))
      * ($y-$xFloor)/($xCeil-$xFloor));
  },

  yCoordToValue => sub($$) {
    my $self = shift;
    my $y = shift;

    my $xFloor = 0;
    my $xCeil = $self->ycCeil();

    my $yFloor  = $self->_yMin();
    my $yCeil   = $self->_yMax();

    return sprintf('%.01f',
      $yCeil - (($yCeil-$yFloor) * ($y-$xFloor)/($xCeil-$xFloor))
    );
  },

  ycCeil => sub($) {
    my $self = shift;

    return $self->height()-25;
    # return $self->height()-1;
  },

  xcFloor => sub($) {
    my $self = shift;

    return 30;
    # return 0;
  },

  render => sub($) {
    my $self = shift;

    return undef if !$self->{_series};

    # $self->setBgColor(32,32,32);
    $self->setBgColor(255,255,255);
    $self->setGridColor(128,128,128,.1);
    $self->setUnitColor(96,96,96,.6);

    $self->setColors(
      # Neat site
      # http://www.personal.psu.edu/cab38/ColorBrewer/ColorBrewer.html

      # green
      [ 35, 200, 69 ], [ 116, 196, 118 ], [ 186, 228, 179 ],
      # orange
      [ 250, 92, 1 ], [ 253, 161, 60 ], [ 253, 210, 133 ],
      # red
      [ 250, 24, 29 ], [ 251, 106, 74 ], [ 252, 174, 145 ],
      # gray
      [ 150, 150, 150 ], [ 200, 200, 200 ], [ 250, 250, 250 ],
      # pink
      [ 250, 64, 126 ], [ 251, 104, 161 ], [ 252, 180, 185 ],
      # lavender i guess
      [ 106, 81, 163 ], [ 158, 154, 200 ], [ 203, 201, 226 ],
      # blue
      [ 33, 113, 181 ], [ 107, 174, 214 ], [ 189, 215, 231 ],
    );

    if ( !$self->{_image} ) {
      my $image = Image::Magick->new(
        magick => 'png'
      );

      $image->Set(size=> join("x", $self->width(), $self->height()));
   
      $image->ReadImage(sprintf('xc:rgba(%s,0)',$self->bgColor()->join(',')));

      $self->{_image} = $image;
    }

    #
    # Stack-based fun:
    #
    # Polygons need to be painted in reverse order, but before text
    # and markers.
    #
    # To take care of this, anonymous sub{ } blocks which render the
    # chart elements are unshifted or pushed onto a stack. The subs in the
    # stack run in sequence, after in-memory series stacking operations
    # are complete.
    #
    # Any sub{ } blocks added to a stack *must* be shifted or popped off,
    # or massive memory leaks will result.
    #
    my $lineStack  = OP::Array->new();
    my $shapeStack = OP::Array->new();
    my $labelStack = OP::Array->new();

    my $base = { };
    my $prev = { };
    my $xTicks = OP::Hash->new();
    my $xTicksY = OP::Hash->new();

    my $prevLabelHeight;

    $self->{_series}->each( sub {
      my $series = $_;

      my $color = $self->colors()->shift();
      $self->colors()->push($color);

      my $data = $series->cooked();
      my $keys = $data->keys();

      my $lastXC;
      my $lastY;
      my $lastYC;

      my $firstYC;

      my $points = $keys->collect(sub {
        my $x = $_;
        my $y = $data->{$x};
        my $rawY = $y;

        my $baseY = 0;

        if ( $self->stacked() ) {
          for ( @{ $self->{_series} } ) {
            last if $_ == $series;

            $baseY += $_->yForX($x);
          }
        }

        $y += $baseY;

        my ($xc, $yc) = ($self->xValueToCoord($x), $self->yValueToCoord($y));

        $prev->{$xc} = $self->ycCeil() if !defined $prev->{$xc};

        my $baseYC = $self->yValueToCoord($baseY);
        $firstYC = $yc if !defined $firstYC;

        my $offset = $self->stacked()
          # ? ( $prev->{$xc} - $yc ) * .2
          ? ( $baseYC - $yc ) * .2
          : ( ( $self->ycCeil() - $yc ) * .075 );

        $offset = 0.1 if $offset <= 0.1;

        if (
          ( $series->yInterpolate() == OP::Enum::Inter::Constant )
            && $rawY == $lastY
        ) {
          $lastY = $rawY;
          $lastYC = $yc;

          return();
	}

        my $xNudge = 0;

        if ( $series->yInterpolate() == OP::Enum::Inter::Constant ) {
          if ( $xc == $self->xcFloor() ) {
            if ( $keys->size() > 1 ) {
              my $next;

              for my $key ( @$keys ) {
                $next = $key;
                last if $data->{$key} != $rawY;
              }

              $xNudge = ( $self->xValueToCoord($next) - $xc ) / 2;
            } else {
              $xNudge = ( $self->width() - 1 - $xc ) / 2;
            }
          } else {
            $xNudge = ( $xc - $lastXC ) / 2;
          }
        }

        $xTicks->{$xc} = $x;
        $xTicksY->{$xc} = $yc;

        my $coord;

        if ( $self->stacked() ) {
          $coord = sprintf(
            '%i,%i %i,%i',
            $xc+$xNudge,$yc+($offset*2.5),
            $xc+$xNudge+$offset,$yc+($offset*4)
          );
        } else {
          $coord = sprintf(
            '%i,%i %i,%i',
            $xc+$xNudge,$yc,
            $xc+$xNudge+$offset,$yc+($offset*2)
          );
        }

        my $smallStack = 6;

        if ( $series->yInterpolate() == OP::Enum::Inter::Constant ){
          $smallStack = 4;
        }
        $shapeStack->push( sub {
          if ( !$self->stacked() ) {
            return();
          } elsif ( $xc < $self->xcFloor() + 20 &&
              $series->yInterpolate() != OP::Enum::Inter::Constant
          ) {
            return();
          } elsif ( $xc > $self->width() - 20 ) {
            return();
          } elsif ( $self->height() < 240 ) {
            return();
          } elsif ( $self->{_series}->size <= $smallStack ) {
            return();
          } else {
            my $stroke = $self->height() < 240
              ? sprintf('rgba(%s)', join(',',@$color,.16))
              : 'none';
       
            my $err = $self->{_image}->Draw(
              primitive => 'circle',
              points => $coord,
              fill => sprintf('rgba(%s)', join(',',@$color,.16)),
              stroke => $stroke
            );

            die $err if $err;
          };
        } );

        $labelStack->unshift( sub {
          $self->{_image}->Draw(
            primitive => 'circle',
            points => sprintf('%i,%i %i,%i', $xc,$yc,$xc+4,$yc+4),
            fill => sprintf('rgba(%s)', join(',',@$color,.16)),
            stroke => "None"
          );

          my $adjXC = $xc;
          my $align = "Center";

          if (
            ( $adjXC < $self->xcFloor() + 100 )
              || ( $adjXC > $self->width() - 40 )
              || ( $self->height() < 320 )
          ) {
            return();
          }

          my $pointsize = $self->stacked()
            && $self->{_series}->size() > $smallStack 
            ? 3 * sqrt($offset) : 2 * sqrt($offset);

          $pointsize = 9 if $pointsize < 9;
          $pointsize = 18 if $pointsize > 18;

          my $err = $self->{_image}->Annotate(
            font => '/tmp/Lucida_Grande.ttf',
            pointsize => $pointsize,
            x => $adjXC + $xNudge + 1,
            y => $self->stacked() ? $yc+($offset*2.75) + 1 : $yc + 1,
            fill => sprintf('rgba(%s)', join(',',@{ $self->bgColor() },.75)),
            text => sprintf('%.02f',$rawY),
            align => $align
          );

          die $err if $err;

          $err = $self->{_image}->Annotate(
            font => '/tmp/Lucida_Grande.ttf',
            pointsize => $pointsize,
            x => $adjXC + $xNudge,
            y => $self->stacked() ? $yc+($offset*2.75) : $yc,
            fill => sprintf('rgba(%s)', join(',',@$color,1)),
            text => sprintf('%.02f',$rawY),
            align => $align
          );

          die $err if $err;
        } );

        $lastXC = $xc;
        $prev->{$xc} = $yc;

        my $pointset = OP::Array->new();

        if (
          defined $lastYC
            && $series->yInterpolate() == OP::Enum::Inter::Constant
        ) {
          $pointset->push( join(",", $xc, $lastYC) );
        }

        $pointset->push( join(",", $xc, $yc) );

        $lastY = $rawY;
        $lastYC = $yc;

        OP::Array::yield @$pointset;
      } );

      my $labelHeight = $firstYC;

      if ( $prevLabelHeight ) {
        until ( $labelHeight < $prevLabelHeight - 10 ) {
          $labelHeight--;
        }
      }

      $prevLabelHeight = $labelHeight;

      if ( $self->{_series}->size() > 1 && $series->name() ) {
        $labelStack->push( sub {
          my $pointsize = 9;
          my $align = "Left";

          my $err = $self->{_image}->Annotate(
            font => '/tmp/Lucida_Grande.ttf',
            pointsize => $pointsize,
            x => $self->xcFloor() + 1,
            y => $labelHeight,
            fill => sprintf('rgba(%s)', $self->bgColor()->join(","),.5),
            text => $series->name(),
            align => $align
          );

          die $err if $err;

          $err = $self->{_image}->Annotate(
            font => '/tmp/Lucida_Grande.ttf',
            pointsize => $pointsize,
            x => $self->xcFloor() + 2,
            y => $labelHeight - 1,
            fill => sprintf('rgba(%s)', join(',',@$color,1)),
            text => $series->name(),
            align => $align
          );

          die $err if $err;
        } );
      }

      $points->unshift( sprintf('%i,%i',$self->xcFloor(),$firstYC) );
      $points->unshift( sprintf('%i,%i',$self->xcFloor(),$self->ycCeil()) );
      $points->push( sprintf('%i,%i',$self->width()-1,$lastYC));
      $points->push( sprintf('%i,%i',$self->width()-1,$self->ycCeil()) );

      my $stroke = ($self->height() < 320) || $self->{_series}->size() <= 8
        ? sprintf('rgba(%s)', join(',',@$color,.5))
        : sprintf('rgba(%s)', join(',',@$color,.5));
        # : 'none';

      $lineStack->unshift( sub {
        # if ( $self->stacked() ) 
        {
          my $err = $self->{_image}->Draw(
            primitive => 'polygon',
            points => $points->join(" "),
            fill => sprintf('rgba(%s,.5)', $self->bgColor()->join(',')),
            stroke => "none",
          );

          die $err if $err;
        }

        my $err = $self->{_image}->Draw(
          primitive => 'polygon',
          points => $points->join(" "),
          fill => sprintf('rgba(%s)', join(',',@$color,.125)),
          stroke => $stroke
        );

        die $err if $err;
      } );
    } );

    #
    # ALWAYS FULLY UNLOAD STACKS with shift() or pop(), or suffer
    # the bloaty consequences.
    #
    while ( @{ $lineStack } ) { &{ $lineStack->shift() } }
    while ( @{ $shapeStack } ) { &{ $shapeStack->shift() } }

    my $prevXC = 0;

    $xTicks->keys()->sort(sub{ shift() <=> shift() })->each( sub {
      my $x = $_;

      if ( $prevXC + 72 > $x ) { return(); }

      $prevXC = $x;

      my $err = $self->{_image}->Draw(
        primitive => 'line',
        points => join(',',$x,0,$x,$self->height()-1),
        stroke => sprintf('rgba(%s)',$self->gridColor()->join(',')),
      );

      die $err if $err;

      if (
        ( $x == $xTicks->keys()->min() ) 
          || ( $x == $xTicks->keys()->max() )
          || ( $x < $self->xcFloor() + 20 )
          || ( $x > $self->width() - 20 )
      ) {
        return();
      }

      $err = $self->{_image}->Annotate(
        font => '/tmp/Lucida_Grande.ttf',
        pointsize => 10,
        x => $x + 3,
        # y => 4,
        y => $self->ycCeil() + 10,
        fill => sprintf('rgba(%s)',$self->unitColor()->join(',')),
        text => OP::Utility::date($xTicks->{$x}) ."\n".
          OP::Utility::time($xTicks->{$x}),
        align => "Center",
        # rotate => 90,
      );

      die $err if $err;
    } );

    #
    # Left border
    #
    $self->{_image}->Draw(
      primitive => 'line',
      points => join(
        ',',$self->xcFloor(),$self->ycCeil(),$self->width()-1,$self->ycCeil()
      ),
      stroke => "rgba(128,128,128,.85)",
    );

    #
    # Bottom border
    #
    $self->{_image}->Draw(
      primitive => 'line',
      points => join(',',$self->xcFloor(),0,$self->xcFloor(),$self->ycCeil()),
      stroke => "rgba(128,128,128,.85)",
    );

    #
    # Right border
    #
    $self->{_image}->Draw(
      primitive => 'line',
      points => join(',',$self->width()-1,0,$self->width()-1,$self->ycCeil()),
      stroke => "rgba(128,128,128,.85)",
    );

    #
    # Top border
    #
    # $self->{_image}->Draw(
      # primitive => 'line',
      # points => join(',',$self->xcFloor(),0,$self->width()-1,0),
      # stroke => "rgba(128,128,128,.85)",
    # );

    # my $prevLabel;

    for ( my $y = $self->ycCeil(); $y >= 0; $y -= 35 ) {
      my $err = $self->{_image}->Draw(
        primitive => 'line',
        points => join(',',0,$y,$self->width()-1,$y),
        stroke => sprintf('rgba(%s)',$self->gridColor()->join(',')),
      );

      die $err if $err;

      my $label = $self->yCoordToValue($y);

      # next if $prevLabel && $label == $prevLabel;

      $err = $self->{_image}->Annotate(
        font => '/tmp/Lucida_Grande.ttf',
        pointsize => 10,
        x => $self->xcFloor()-2,
        y => $y + 8,
        fill => sprintf('rgba(%s)',$self->unitColor()->join(',')),
        text => $label,
        align => "Right",
      );

      die $err if $err;

      # $prevLabel = $label;
    }

    if ( $self->{_series}->size() == 1 ) {
      $self->{_image}->Annotate(
        font => '/tmp/Lucida_Grande.ttf',
        pointsize => 11,
        x => ( $self->xcFloor() + $self->width() - 1 ) / 2,
        y => 14,
        fill => sprintf('rgba(%s)',$self->unitColor()->join(',')),
        text => $self->{_series}->first()->name(),
        align => "Center",
      );

      $self->{_image}->Annotate(
        font => '/usr/share/X11/fonts/TTF/luxisb.ttf',
        pointsize => 24,
        x => $self->width() - 20,
        y => $self->ycCeil() - 20,
        fill => sprintf('rgba(%s)',$self->unitColor()->join(',')),
        text => sprintf('Avg: %.02f%', $self->{_series}->first()->_prepped()->values()->average()),
        align => "Right",
      );
    }

    while ( @{ $labelStack } ) { &{ $labelStack->shift() } }

    my @blobs = $self->{_image}->ImageToBlob();

    OP::Array::yield( $blobs[0] );
  },
};
__END__
=pod

=head1 NAME

OP::SeriesChart - Experimental image-based series visualizer

=head1 SYNOPSIS

TODO: Write me

=head1 SEE ALSO

This file is part of L<OP>.

=cut
