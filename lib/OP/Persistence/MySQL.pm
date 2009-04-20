#
# File: OP/Persistence/MySQL.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Persistence::MySQL;

=pod

=head1 NAME

OP::Persistence::MySQL - Handle GlobalDBI setup for MySQL/InnoDB

=head1 FUNCTION

=over 4

=item * C<connect(%args)>

Constructor for a MySQL GlobalDBI object.

C<%args> is a hash with keys for C<database> (database name), C<host>,
C<port>, C<user>, and C<pass>.

Returns a new L<GlobalDBI> instance.

=back

=cut

use strict;
use warnings;

use GlobalDBI;

use constant RefOpts => [ "CASCADE", "SET NULL", "RESTRICT", "NO ACTION" ];

sub connect {
  my %args = @_;

  my $dsn = sprintf('DBI:mysql:database=%s;host=%s;port=%s',
    $args{database}, $args{host}, $args{port}
  );

  $GlobalDBI::CONNECTION{$args{database}} ||= [
    $dsn, $args{user}, $args{pass}, { RaiseError => 1 }
  ];

  return GlobalDBI->new(dbname => $args{database});
}

=pod

=head1 SEE ALSO

L<GlobalDBI>, L<DBI>, L<DBD::mysql>

L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISON

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Persistence/MySQL.pm#3 $

=cut

1;
