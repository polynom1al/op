#
# File: OP/Recur/At.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Recur::At;

use strict;
use warnings;

use base qw| OP::Array |;

sub new {
  my $class = shift;

  if ( @_ == 1 && UNIVERSAL::isa($_[0],"OP::Array") ) {
    return $class->SUPER::new(@{$_[0]});
  } else {
    my @self = reverse( pop, pop, pop, pop, pop, pop );

    return $class->SUPER::new(@self);
  }
}

sub year   { return $_[0]->[0]; }
sub month  { return $_[0]->[1]; }
sub day    { return $_[0]->[2]; }
sub hour   { return $_[0]->[3]; }
sub minute { return $_[0]->[4]; }
sub second { return $_[0]->[5]; }

sub _next {
  my $self = shift;
  my $when = shift || $OP::Recur::TIME;

  my @time = localtime($when);

  my $year   = $self->year();
  my $month  = $self->month();
  my $day    = $self->day();
  my $hour   = $self->hour();
  my $minute = $self->minute();
  my $second = $self->second();


  if ( !defined $second ) { $second = $time[0]; }
  if ( !defined $minute ) { $minute = $time[1]; }
  if ( !defined $hour )   { $hour   = $time[2]; }
  if ( !defined $day )    { $day    = $time[3]; }
  if ( !defined $month )  { $month  = $time[4] + 1; }
  if ( !defined $year )   { $year   = $time[5] + 1900; }

  if ( $day == -1 ) {
    $day = Date::Calc::Days_in_Month($year,$month);
  }

  my $time = Time::Local::timelocal(
    $second, $minute, $hour, $day, $month - 1, $year - 1900
  );

  return $time if $time > $when;

  #
  #
  #
  if ( defined $self->year ) {
    warn "Event will never recur";

    return undef;
  }

  my $offset = 1;

  if ( defined $self->month ) {
    #
    # Month has passed; reschedule for next year.
    #
    my @now = localtime;

    $offset = Time::Local::timelocal(
      $second, $minute, $hour, $day, $month, $now[5] + 1
    ) - $time;
  } elsif ( defined $self->day ) {
    #
    # Day has passed; reschedule for next month.
    #
    my @nextMonth = localtime Date::Manip::UnixDate(
      Date::Manip::ParseDate("next month"), '%s'
    );

    $offset = Time::Local::timelocal(
      $second, $minute, $hour, $nextMonth[3], $nextMonth[4], $nextMonth[5]
    ) - $time;
  } elsif ( defined $self->hour ) {
    #
    # Hour has passed, reschedule for tomorrow.
    #
    my @tomorrow = localtime Date::Manip::UnixDate(
      Date::Manip::ParseDate("tomorrow"), '%s'
    );

    $offset = Time::Local::timelocal(
      $second, $minute, $hour, $tomorrow[3], $tomorrow[4], $tomorrow[5]
    ) - $time;
  } elsif ( defined $self->minute ) {
    #
    # Minute has passed, try again next hour
    #
    $offset = 60*60;
  } elsif ( defined $self->second ) {
    #
    # Second has passed, try again next minute
    #
    $offset = 60;
  }

  return OP::DateTime->new( $time + $offset );
}

1;
__END__
=pod

=head1 NAME

OP::Recur::At

=head1 SYNOPSIS

This module should not be used directly. See L<OP::Recur>.

=head1 SEE ALSO

This file is part of L<OP>.

=cut
