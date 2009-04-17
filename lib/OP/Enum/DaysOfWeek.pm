#
# File: OP/Enum/DaysOfWeek.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::DaysOfWeek;

use OP::Enum qw| MON=1 TUE WED THU FRI SAT SUN |;

eval { @EXPORT = @EXPORT_OK };

=pod

=head1 NAME

OP::Enum::DaysOfWeek - Named days of week (English)

=head1 SYNOPSIS

  use OP::Enum::DaysOfWeek;

=head1 CONSTANTS

=over 4

=item * MON

1

=item * TUE

2

=item * WED

3

=item * THU

4

=item * FRI

5

=item * SAT

6

=item * SUN

7

=back

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/DaysOfWeek.pm#1 $

=cut

1;
