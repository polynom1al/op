#
# File: OP/Enum/DBIType.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::DBIType;

use OP::Enum qw| MySQL SQLite |;

=head1 NAME

OP::Enum::DBIType

=head1 DESCRIPTION

Database type enumeration.

Uses L<OP::Enum> to provide constants which are used to specify database
types. The mix-in L<OP::Persistence> class method C<__dbiType()> should
be overridden in a subclass to return one of the constants in this package.

=head1 SYNOPSIS

  use OP::Enum::DBIType;

  sub __dbiType($) {
    my $class = shift;

    return OP::Enum::DBIType::MySQL;
  }

=head1 CONSTANTS

=over 4

=item * C<OP::Enum::DBIType::MySQL>

Specifies MySQL as a DBI type

=item * C<OP::Enum::DBIType::SQLite>

Specifies SQLite as a DBI type

=back

=head1 SEE ALSO

L<OP::Enum>, L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/DBIType.pm#2 $

=cut

1;
