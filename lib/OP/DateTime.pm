#
# File: OP/DateTime.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#

#
# Time::Piece overrides localtime/gmtime in caller, which breaks assumptions
#
# Override Time::Piece to not override:
#
package OP::DateTime;

use strict;
use warnings;

do {
  package Time::Piece::Nonpolluting;

  use strict;
  use warnings;

  use base qw| Time::Piece |;

  our @EXPORT = qw| |;

  sub import { }

  sub export { }
};

use OP::Class qw| true false |;
use Perl6::Subs;
use Scalar::Util qw| blessed |;

use base qw| Time::Piece::Nonpolluting OP::Array |;

use overload (
  '""'  => '_sprint',
  '<=>' => '_compare',
);

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    sub {
      UNIVERSAL::isa($_[0], "Time::Piece")
       || Scalar::Util::looks_like_number("$_[0]")
       || throw OP::AssertFailed("Received value is not a time");
    }, @rules
  );

  $parsed{min} = 0 if !defined $parsed{min};
  $parsed{max} = 2**32 if !defined $parsed{max};
  $parsed{default} ||= "0.0000";
  $parsed{columnType} ||= 'DOUBLE(15,4)';

  return $class->__assertClass()->new(%parsed);
};

method new(OP::Class $class: Any $time) {
  my $epoch = 0;

  my $blessed = blessed($time);

  if ( $blessed && $time->can("epoch") ) {
    $epoch = $time->epoch();
  } elsif ( $blessed && overload::Overloaded($time) ) {
    $epoch = "$time";
  } else {
    $epoch = $time;
  }

  OP::Type::insist($epoch, OP::Type::isFloat);

  my $self = Time::Piece::Nonpolluting->new($epoch);

  return bless $self, $class;
};

#
# Allow comparison of DateTime, Time::Piece, overloaded scalar,
# and raw number values.
#
# Overload is retarded for sometimes reversing these, what the actual hell
#
sub _compare {
  my $date1 = $_[2] ? $_[1] : $_[0];
  my $date2 = $_[2] ? $_[0] : $_[1];

  if ( blessed($date1) && $date1->can("epoch") ) {
    $date1 = $date1->epoch();
  }

  if ( blessed($date2) && $date2->can("epoch") ) {
    $date2 = $date2->epoch();
  }

  return $date1 <=> $date2;
};

sub _sprint {
  return shift->epoch()
};

#
# Deny all knowledge of being OP::Array-like.
#
# DateTime wants to be treated like a scalar when it comes to just about
# everything.
#
sub isa {
  my $recv = shift;
  my $what = shift;

  return false if $what eq 'OP::Array';

  return UNIVERSAL::isa($recv,$what);
}

true;

__END__

=pod

=head1 NAME

OP::DateTime

=head1 VERSION

  $Id: //depotit/tools/source/snitchd-0.20/lib/OP/DateTime.pm#15 $

=head1 SYNOPSIS

  use OP::DateTime;

  my $time = OP::DateTime->new( time() );

=head1 DESCRIPTION

Time object.

Extends L<OP::Object>, L<Time::Piece>. Overloaded for numeric comparisons,
stringifies as unix epoch seconds unless overridden.

=head1 PUBLIC CLASS METHODS

=over 4

=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::DateTime instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    someTimestamp  => OP::DateTime->assert(optional()),

    # ...
  };

=item * C<new(OP::Class $class: Num $epoch)>

Returns a new OP::DateTime instance which encapsulates the received value.

  my $object = OP::DateTime->new($epoch);

=back

=head1 SEE ALSO

See the L<Time::Piece> module for time formatting and manipulation
methods inherited by this class.

This file is part of L<OP>.

=cut
