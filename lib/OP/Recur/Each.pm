#
# File: OP/Recur/Each.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Recur::Each;

use strict;
use warnings;

use base qw| OP::Array |;

use OP::Enum::Bool;

#
# each(Sunday)
# each(Monday, March);
# each(Thursday, November, 2000);
#

sub wday  { return $_[0]->[0]; }
sub month { return $_[0]->[1]; }
sub year  { return $_[0]->[2]; }

sub includes {
  my $self = shift;
  my $now = shift || $OP::Recur::TIME;

  my @now = localtime($now);

  my $haveYear  = $now[5] + 1900;
  my $haveMonth = $now[4] + 1;
  my $haveWDay  = $now[6];

  return false if defined($self->year) && $self->year != $haveYear;
  return false if defined($self->month) && $self->month != $haveMonth;
  return false if defined($self->wday) && $self->wday != $haveWDay;

  return true;
}

sub excludes {
  my $self = shift;
  my $time = shift;

  return $self->includes($time) ? false : true;
}

1;
__END__
=pod

=head1 NAME

OP::Recur::Each

=head1 SYNOPSIS

This module should not be used directly. See L<OP::Recur>.

=head1 SEE ALSO

This file is part of L<OP>.

=cut 
