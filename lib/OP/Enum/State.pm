#
# File: OP/Enum/State.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::State;

use OP::Enum qw| OK Warn Crit |;

eval {
  @EXPORT = @EXPORT_OK;
};

=head1 NAME

OP::Enum::State - Criticality enumeration

=head1 DESCRIPTION

Exports "Nagios-style" states: OK (0), Warn (1), and Crit (2).

=head1 SYNOPSIS

  use OP::Enum::State;

  sub foo($) {
    ...

    return OK if $ok;
    return Warn if $warn;
    return Crit if $crit;
  }

=head1 CONSTANTS

=over 4

=item * C<OP::Enum::State::OK>

0

=item * C<OP::Enum::State::Warn>

1

=item * C<OP::Enum::State::Crit>

2

=back

=head1 SEE ALSO

L<OP::Enum>, L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/State.pm#2 $

=cut

1;
