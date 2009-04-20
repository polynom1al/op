#
# File: OP/Double.pm
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

OP::Double - Scalar-backed overloaded object class for doubles

=head1 DESCRIPTION

Functionally the same as OP::Float. Used for differentiating between
database-backed datatypes.

Extends L<OP::Float>.

=head1 SYNOPSIS

  use OP::Double;

  use bignum; # Optional

  my $double = OP::Double->new("12345678.12345678");

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Double;

use strict;
use warnings;

use Perl6::Subs;

use OP::Enum::Bool;

use base qw| OP::Float |;

use overload fallback => true, %OP::Num::overload;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isFloat, @rules
  );

  $parsed{default} = "0.0000000000" if !defined $parsed{default};
  $parsed{columnType}  ||= 'DOUBLE(30,10)';

  return $class->__assertClass()->new(%parsed);
}

1;
