#
# File: OP/Rule.pm
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

OP::Rule - Object class for regular expressions

=head1 DESCRIPTION

Extends L<OP::Ref>

=head1 SYNOPSIS

  use OP::Rule;

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Rule;

use strict;
use warnings;

use OP::Enum::Bool;

use Perl6::Subs;

use overload
  '""' => sub { shift->value() };

use base qw| OP::Ref |;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isRule, @rules
  );

  return $class->__assertClass()->new(%parsed);
}

method sprint() {
  return "$self";
}

true;
