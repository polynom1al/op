#
# File: OP/Redefines.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
no warnings "redefine";

package Scalar::Util;

#
# Override looks_like_number to recognize Num objects as numbers
#
sub looks_like_number($) {
  local $_ = shift;

  return 0 if !defined($_);
  return 0 if ref($_) && !UNIVERSAL::isa($_, "OP::Num");
  return 1 if (/^[+-]?\d+$/); # is a +/- integer
  return 1 if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/); # a C float
  return 1 if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i) or ($] >= 5.006001 and /^Inf$/i);

  0;
}

package Perl6::Subs;

$Carp::Internal{ __PACKAGE__ }++;

sub _error {
  my $sub = (caller(0))[3];
  my ($c_file, $c_line) = (caller(0))[1, 2];

  #
  # Being inside of an eval can throw the caller index off
  #
  # if ( !$c_file ) {
    # ($c_file, $c_line) = (caller(1))[1, 2];
  # }

  my $msg = join '', @_;
  $msg .= " in call to $sub" unless $sub =~ /^\(/;
  $msg .= " at $c_file line $c_line";

  throw OP::InvalidArgument( $msg );
}

use warnings "redefine";

1;
__END__
=pod

=head1 NAME

OP/Redefines.pm - Runtime overrides for OP

=head1 SYNOPSIS

This module should not be used directly. OP uses it at load time.

=head1 SEE ALSO

This file is part of L<OP>.

=cut
