#
# File: OP/Int.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
=pod

=head1 NAME

OP::Int - Overloaded object class for integers

=head1 DESCRIPTION

Extends L<OP::Num> and L<Data::Integer>.

=head1 SYNOPSIS

  use OP::Int;

  my $int = OP::Int->new(42);

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Int;

use strict;
use warnings;

use Perl6::Subs;

use OP::Enum::Bool;

use base qw| OP::Num Data::Integer |;

use overload fallback => true, %OP::Num::overload;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isInt, @rules
  );

  $parsed{maxSize} ||= 11;
  $parsed{columnType} ||= 'INT(11)';

  return $class->__assertClass()->new(%parsed);
}

1;
