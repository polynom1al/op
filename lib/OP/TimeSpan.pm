#
# File: OP/TimeSpan.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::TimeSpan;

use strict;
use warnings;

use OP::Class qw| true false |;
use OP::Num;
use Perl6::Subs;

use Time::Seconds;

use base qw| Time::Seconds OP::Scalar |;

use overload fallback => true,
  '<=>' => '_compare',
  %OP::Num::overload;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    sub {
      UNIVERSAL::isa($_[0], "DateTime")
       || Scalar::Util::looks_like_number("$_[0]")
       || throw OP::AssertFailed("Received value is not a time");
    }, @rules
  );

  $parsed{min} = 0 if !defined $parsed{min};
  $parsed{max} = 2**32 if !defined $parsed{max};
  $parsed{default} ||= "0.0000" if !defined $parsed{default};
  $parsed{columnType} ||= 'DOUBLE(15,4)';

  return $class->__assertClass()->new(%parsed);
};

sub _compare {
  my $date1 = $_[2] ? $_[1] : $_[0];
  my $date2 = $_[2] ? $_[0] : $_[1];

  $date1 ||= 0;
  $date2 ||= 0;

  return "$date1" <=> "$date2";
};

true;

__END__

=pod

=head1 NAME

OP::TimeSpan - Time range object class

=head1 VERSION

  $Id: //depotit/tools/source/snitchd-0.20/lib/OP/TimeSpan.pm#8 $

=head1 SYNOPSIS

  use OP::TimeSpan;

  my $time = OP::TimeSpan->new( 60*5 );

=head1 DESCRIPTION

Extends L<OP::Object>, L<Time::Seconds>.

Stringifies as number of seconds unless overridden.

=head1 PUBLIC CLASS METHODS

=over 4

=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::TimeSpan instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    someTime  => OP::TimeSpan->assert(optional()),

    # ...
  };

=item * C<new(OP::Class $class: Num $secs)>

Returns a new OP::TimeSpan instance which encapsulates the received value.

  my $object = OP::TimeSpan->new($secs);

=back

=head1 SEE ALSO

See the L<Time::Seconds> module for time formatting and manipulation
methods inherited by this class.

This file is part of L<OP>.

=cut
