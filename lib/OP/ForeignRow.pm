#
# File: OP/ForeignRow.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
use OP;

use OP::Constants qw| dbHost dbPass dbPort dbUser |;

create "OP::ForeignRow" => {
  __init => method(OP::Class $class:) { },

  __baseAsserts => method(OP::Class $class:) {
    my $asserts = $class->get('DBIASSERTS');

    if ( !$asserts ) {
      $asserts = { };

      my $sth = $class->query( sprintf q| describe %s |,
        $class->tableName
      );

      # XXX TODO assert these properly
      # Default: ~
      # Extra: ''
      # Field: flappiness
      # Key: ''
      # "Null": 'YES'
      # Type: float

      while ( my $row = $sth->fetchrow_hashref() ) {
        $asserts->{$row->{Field}} = OP::Str->assert(::optional, ::maxSize(1024*5));
      }

      $class->set('DBIASSERTS', $asserts);
    }

    return $asserts;
  },

  __DSN => method(OP::Class $class:) {
    return sprintf( $class->__DSNSTRING(),
      $class->__DBNAME(), $class->__DBHOST(), $class->__DBPORT()
    );
  },

  __DSNSTRING => method(OP::Class $class:) {
    my $str = $class->get("__DSNSTRING");

    if ( !$str ) {
      $str = 'DBI:mysql:database=%s;host=%s;port=%s';
      $class->set("__DSNSTRING", $str);
    }

    return $str;
  },

  __DBNAME  => method(OP::Class $class:) {
    my $dbName = $class->get("__DBNAME");

    if ( !$dbName ) {
      $dbName = $class->databaseName();
      $class->set("__DBNAME", $dbName);
    }

    return $dbName;
  },

  __DBHOST  => method(OP::Class $class:) {
    my $dbHost = $class->get("__DBHOST");

    if ( !$dbHost ) {
      $dbHost = dbHost;
      $class->set("__DBHOST", $dbHost);
    }

    return $dbHost;
  },

  __DBPORT  => method(OP::Class $class:) {
    my $dbPort = $class->get("__DBPORT");

    if ( !$dbPort ) {
      $dbPort = dbPort;
      $class->set("__DBPORT", $dbPort);
    }

    return $dbPort;
  },

  __DBUSER  => method(OP::Class $class:) {
    my $dbUser = $class->get("__DBUSER");

    if ( !$dbUser ) {
      $dbUser = dbUser;
      $class->set("__DBUSER", $dbUser);
    }

    return $dbUser;
  },

  __DBPASS  => method(OP::Class $class:) {
    my $dbPass = $class->get("__DBPASS");

    if ( !$dbPass ) {
      $dbPass = dbPass;
      $class->set("__DBPASS", $dbPass);
    }

    return $dbPass;
  },

  __dbh => method(OP::Class $class:) {
    my $dbName = $class->__DBNAME();

    my $dbi = $class->get("__DBI");

    if ( !$dbi ) {
      $dbi = { }; 

      $class->set("__DBI", $dbi);
    }

    $dbi->{$dbName} ||= { };

    local %GlobalDBI::CONNECTION;
    local %GlobalDBI::DBH;

    if ( !$dbi->{$dbName}->{$$} ) {
      my $dsn = $class->__DSN();
      my $dbName = $class->__DBNAME();

      $GlobalDBI::CONNECTION{$dbName} ||= [
        $dsn, $class->__DBUSER(), $class->__DBPASS(), { RaiseError => 1 }
      ];

      $dbi->{$dbName}->{$$} = GlobalDBI->new(dbname => $dbName);
    }

    return $dbi->{$dbName}->{$$}->get_dbh();
  },

  tableName => method(OP::Class $class:) {
    my $tableName = $class->get("__TABLENAME");

    if ( !$tableName ) {
      $tableName = OP::Persistence::tableName($class);

      $class->set("__TABLENAME", $tableName);
    }

    return $tableName;
  },

  loadByName => method(OP::Class $class: Str $name) {
    my $query = sprintf( q|
      select * from %s where name = %s
    |, $class->tableName, $class->quote($name) );

    my $self = $class->__loadFromQuery($query);

    unless ( $self && $self->exists() ) {
      warn "Object $name does not exist in database";

      return;
    }

    return $self;
  },

  save => method() {
    die "This isn't happening today";
  },

  exists => method() {
    return $self->class->doesNameExist($self->name);
  },

};
__END__
=pod

=head1 NAME

OP::ForeignRow - Foreign database row access

=head1 SYNOPSIS

This is an abstract class.

Callers should use the factory class L<OP::ForeignTable>.

=head1 SEE ALSO

This file is part of L<OP>.

=cut
