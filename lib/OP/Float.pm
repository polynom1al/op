#
# File: OP/Float.pm
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

OP::Float - Overloaded object class for floating point numbers

=head1 DESCRIPTION

Extends L<OP::Num> and L<Data::Float>.

=head1 SYNOPSIS

  use OP::Float;

  use bignum; # Optional

  my $float = OP::Float->new(22/7);

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Float;

use strict;
use warnings;

use Perl6::Subs;

use OP::Enum::Bool;

use base qw| OP::Num Data::Float |;

use overload fallback => true, %OP::Num::overload;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isFloat, @_
  );

  $parsed{default} = "0.0" if !defined $parsed{default};
  $parsed{columnType}  ||= 'FLOAT';

  return $class->__assertClass()->new(%parsed);
}

1;
