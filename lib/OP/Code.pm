#
# File: OP/Code.pm
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

OP::Code - Object class for code blocks

=head1 DESCRIPTION

Extends L<OP::Ref>

=head1 SYNOPSIS

  use OP::Code;

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Code;

use strict;
use warnings;

use Perl6::Subs;

use base qw| OP::Ref |;

method new(OP::Class $class: Code $code) {
  return $class->SUPER::new($code);
}

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isCode, @rules
  );

  $parsed{columnType} ||= "TEXT";

  return $class->__assertClass()->new(%parsed);
}

1;
