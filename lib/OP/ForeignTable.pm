#
# File: OP/ForeignTable.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
use OP;

create "OP::ForeignTable" => {
  __BASE__ => "OP::Hash",

  db      => OP::Str->assert(::optional),
  host    => OP::Str->assert(::optional),
  port    => OP::Str->assert(::optional),
  user    => OP::Str->assert(::optional),
  table   => OP::Str->assert(::optional),
  pass    => OP::Str->assert(::optional),
  dsnStr  => OP::Str->assert(::optional),

  objectClass => sub {
    my $self = shift;

    my $class = $self->class();

    if ( !$self->{_datasource} ) {
      my $now = CORE::time();
      my $rand = lc(OP::Utility::randstr());

      my $newClass = join("::", 
        $class, join('_', $now, $rand)
      );

      $self->{_datasource} = create $newClass => {
        __BASE__    => "OP::ForeignRow",
        __DSNSTRING => $self->dsnStr,
        __DBNAME    => $self->db(),
        __DBHOST    => $self->host(),
        __DBPORT    => $self->port(),
        __DBUSER    => $self->user(),
        __DBPASS    => $self->pass(),
	__TABLENAME => $self->table(),
      };
    }

    return $self->{_datasource};
  }
};

__END__
=pod

=head1 NAME

OP::ForeignTable

=head1 DESCRIPTION

Class factory for OP::ForeignRow.

OP::ForeignRow responds to the same messages as OP::RRNode, except
ForeignRow objects live in databases of external applications with
schemas which are not defined by OP.

Callers specify DB connection parameters, and ForeignTable returns a
dynamically allocated ForeignRow subclass representing the table
which was described.

=head1 SYNOPSIS

  use OP;

  use OP::ForeignRow;
  use OP::ForeignTable;

  my $table = OP::ForeignTable->new(
    db      => "somedb",
    host    => "somehost",
    table   => "sometable",
    user    => "myuser",
    pass    => "mypass",
  );

  #
  # Return an "anonymous" OP::ForeignRow subclass representing
  # the described datasource. Instances of ForeignRow represent
  # rows in the foreign table.
  #
  my $class = $table->objectClass;

  print $class;
  print "\n";

  $class->allNames->each( sub {
    print "Have name: $_\n";

    my $object = $class->loadByName($_);
  } );

=head1 SEE ALSO

This file is part of L<OP>.

=cut
