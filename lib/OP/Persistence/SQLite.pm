#
# File: OP/Persistence/SQLite.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Persistence::SQLite;

=pod

=head1 NAME

OP::Persistence::SQLite - Handle GlobalDBI setup for SQLite

=head1 FUNCTION

=over 4

=item * C<connect(%args)>

Constructor for a SQLite GlobalDBI object.

C<%args> is a hash with a key for C<database> (database name), which
in SQLite is really a local filesystem path (/path/to/db).

Returns a new L<GlobalDBI> instance.
   
=back

=cut

use strict;
use warnings;

use GlobalDBI;

sub connect {
  my %args = @_;

  my $dsn = sprintf('DBI:SQLite:dbname=%s',$args{database});

  $GlobalDBI::CONNECTION{$args{database}} ||= [
    $dsn, '', '', { RaiseError => 1 }
  ];

  return GlobalDBI->new(dbname => $args{database});
}

=pod

=head1 SEE ALSO

L<GlobalDBI>, L<DBI>, L<DBD::SQLite>

L<OP::Persistence>

This file is part of L<OP>.

=head1 REVISON

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Persistence/SQLite.pm#2 $

=cut

1;
