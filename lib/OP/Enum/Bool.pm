#
# File: OP/Enum/Bool.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::Bool;

=pod

=head1 NAME

OP::Enum::Bool - Boolean enumeration

=head1 DESCRIPTION

Bool enumeration. Uses L<OP::Enum> to provides "true" (1) and "false"
(0) constants for use in Perl applications. Complete syntactical sugar,
basically.

Future versions of Perl will have boolean keywords, at which point this
module should go away.

=head1 SYNOPSIS

  package Foo;

  use OP::Enum::Bool;

  sub foo {
    ...
    return true;
  }

  sub bar {
    ...
    return false;
  }

  true;

=head1 EXPORTS CONSTANTS

=over 4

=item * C<false>

0

=item * C<true>

1

=back

=cut

use OP::Enum qw| false true |;

eval {
  @EXPORT = @EXPORT_OK;
};

=pod

=head1 SEE ALSO

L<OP::Enum>, L<OP::Class>

This file is part of L<OP>.

=head1 REVISION

$Id: $

=cut

true;
