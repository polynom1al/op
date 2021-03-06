#
# File: OP/Enum/Consol.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::Consol;

use OP::Enum qw|
  Average Median Min Max Sum First Last Random
|;

=pod

=head1 NAME

OP::Enum::Consol - Series data consolidation type enumeration

=head1 DESCRIPTION

Specifies datapoint consolidation methods

=head1 SYNOPSIS

  use OP::Enum::Consol;

=head1 CONSTANTS

=over 4

=item * Average

Consolidate multiple values into a single value by averaging

=item * Median

Select the median from a set of multiple values

=item * Min

Select the minimum from a set of multiple values

=item * Max

Select the maximum from a set of multiple values

=item * Sum

Consolidate multiple values into a single value by adding

=item * First

Select the first (oldest) from a set of multiple values

=item * Last

Select the last (newest) from a set of multiple values

=item * Random

Select randomly from a set of multiple values

=back

=head1 SEE ALSO

L<OP::Enum>, L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/Consol.pm#2 $

=cut

1;
