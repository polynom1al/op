#
# File: OP/Exceptions.pm
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

OP::Exceptions - Defines the exceptions which may be thrown inside of OP

=head1 EXCEPTION LIST

See @__types in this package for the current list.

XXX TODO: Automate the process of turning the exception list into docs.

=head1 SEE ALSO

L<Error>, L<OP::Class>

This file is part of L<OP>.

=cut

package OP::Exceptions;

use strict;
use warnings;

#
#
#
my @__types = qw|
  AssertFailed
  ClassAllocFailed
  ClassIsAbstract
  DataConversionFailed
  DBConnectFailed
  DBQueryFailed
  DBSchemaMismatch
  FileAccessError
  GetURLFailed
  InvalidArgument
  LockFailure
  LockTimeoutExceeded
  MethodIsAbstract
  MethodNotFound
  ObjectIsAnonymous
  ObjectNotFound
  PGPDecryptFailed
  PrimaryKeyMissing
  RCSError
  RuntimeError
  StaleObject
  TimeoutExceeded
  TransactionFailed
|;

our @types;

for my $type ( @__types ) {
  my $class = sprintf('OP::%s', $type);

  eval qq|
    package $class;

    use base qw/ Error::Simple /;

    push @types, $class;
  |;
}

1;
