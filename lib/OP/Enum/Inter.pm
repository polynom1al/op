#
# File: OP/Enum/Inter.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::Inter;

use OP::Enum qw| Linear Spline Constant Undefined None |;

=pod

=head1 NAME

OP::Enum::Inter - Interpolation types

=head1 DESCRIPTION

Specifies methods of interpolation between known datapoints.

=head1 SYNOPSIS

  use OP::Enum::Inter;

  my $linear = OP::Enum::Inter::Linear;

  ...

=head1 CONSTANTS

=over 4

=item * Linear

"Straight line" between points

=item * Spline

Cubic spline curve between points

=item * Constant

Use last known value between points

=item * Undefined

Use undef for unknown datapoints

=item * None

Don't interpolate

=back

=head1 SEE ALSO

L<OP::Enum>, L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/Inter.pm#2 $

=cut

1;
