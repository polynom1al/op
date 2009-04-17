#
# File: OP/Enum/MonthsOfYear.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Enum::MonthsOfYear;

use OP::Enum qw| 
  JAN=1 FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC
  _JAN=0 _FEB _MAR _APR _MAY _JUN _JUL _AUG _SEP _OCT _NOV _DEC
|;

eval { @EXPORT = @EXPORT_OK };

=pod

=head1 NAME

OP::Enum::MonthsOfYear - Named days of week (English)

1-Index version constants (where January = 1) are:

  JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC

For 0-Index versions (where January = 0), prepend an underscore.

  _JAN _FEB _MAR _APR _MAY _JUN _JUL _AUG _SEP _OCT _NOV _DEC

=head1 SYNOPSIS

  use OP::Enum::MonthsOfYear;

  print JAN ."\n";

  print _JAN ."\n";

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Enum/MonthsOfYear.pm#1 $

=cut

1;
