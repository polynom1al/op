#
# File: OP/Ref.pm
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

OP::Ref - Object class for references

=head1 DESCRIPTION

Extends L<OP::Any>

=head1 SYNOPSIS

  use OP::Ref;

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Ref;

use strict;
use warnings;

use Perl6::Subs;

no overload;

use base qw| OP::Any |;

method new(OP::Class $class: Str $self) {
  throw OP::InvalidArgument("$class->new() requires a reference for arg")
    if !ref($self);

  return bless $self, $class;
}

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isRef, @rules
  );

  return $class->__assertClass()->new(%parsed);
}

1;
