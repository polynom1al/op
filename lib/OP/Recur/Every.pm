#
# File: OP/Recur/Every.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Recur::Every;

use strict;
use warnings;

use base qw| OP::TimeSpan |;

sub new {
  my $class = shift;
  my $lesser = shift;
  my $greater = shift;

  return defined($greater)
    ? $class->SUPER::new($lesser * $greater)
    : $class->SUPER::new($lesser);
}

sub _next {
  my $self = shift;
  my $now = shift || $OP::Recur::TIME;

  #
  # the 1000 avoids stupid mod 0 errors for fractional times
  #
  my $next = $now - ( (($now*1000) % ($self*1000))/1000 ) + $self;

  $next += $self if $next <= $now;

  return OP::DateTime->new( $next );
} 

1;
__END__
=pod

=head1 NAME

OP::Recur::Every - Time specification object class

=head1 SYNOPSIS

This module should not be used directly. See L<OP::Recur>.

=head1 SEE ALSO

This file is part of L<OP>.

=cut 
