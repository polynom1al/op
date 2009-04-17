#
# File: OP/RRNode.pm
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

OP::RRNode - Circular "Round Robin" Table Rows

=head1 DESCRIPTION

Abstract implementation of a circular FIFO object class.

The DB table for a FIFO subclass will never grow beyond the
limit set by the subclass's C<__numRows> variable. When the row
limit is reached, the oldest rows in the database will begin to be
overwritten.

Suitable applications for subclasses include event logging, message
queueing, and RRD-style data collection.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > L<OP::Object> > L<OP::Hash> > L<OP::Node> > OP::RRNode

=head1 SYNOPSIS

  use strict;
  use warnings;

  use OP::Class;

  create "OP::RRExample" => {
    __BASE__  => "OP::RRNode",
    __numRows => 250000
  }

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/RRNode.pm#6 $

=cut

use OP;

use OP::Enum::DBIType;
use OP::Enum::State;

#
# Implementation of a "Round Robin" object class
#
# References:
#  http://www.xaprb.com/blog/2007/01/11/how-to-implement-a-queue-in-sql/
#
create "OP::RRNode" => {
  #
  # these are wrapped in sub{} so subclasses can inherit:
  #
  __dbiType  => sub { OP::Enum::DBIType::MySQL },
  __useYaml  => sub { false },

  __numRows => sub($) {
    my $class = shift;

    my $numRows = $class->get("__numRows");

    if ( !$numRows ) {
      $numRows = 10;
      $class->set("__numRows", $numRows);
    }

    return $numRows;
  },

  # Overrides OP::Persistence:
  __baseAsserts => sub($) {
    my $class = shift;

    my $asserts = OP::Node->__baseAsserts();

    my $r = $class->__numRows();

    #
    # We want subclasses to inherit these:
    #
    $asserts->{id} = OP::Int->assert(
      ::columnType("BIGINT(20)"),
      ::sqlValue("(coalesce(max(id),-1) + 1)"),
      ::optional()
    );

    $asserts->{modulo} = OP::Int->assert(
      ::default(0),
      ::sqlValue("(coalesce(max(id),-1) + 1) mod $r"),
      ::unique(true),
      ::optional(),
    );

    $asserts->{value}   = OP::Double->assert(
      ::optional(),
    );

    $asserts->{message} = OP::Str->assert(
      ::optional(),
    );

    $asserts->{state}   = OP::Int->assert(
      OK, Warn, Crit,
      ::optional()
    ); # OP::Enum::State

    $asserts->{timestamp} = OP::DateTime->assert(
      ::optional()
    ),

    return $asserts;
  },

  averageValue => sub($) {
    my $class = shift;

    return $class->__selectSingle( sprintf q|
      SELECT avg(value) FROM %s
    |, $class->tableName() )->[0];
  },

  minValue => sub($) {
    my $class = shift;

    return $class->__selectSingle( sprintf q|
      SELECT min(value) FROM %s
    |, $class->tableName() )->[0];
  },

  maxValue => sub($) {
    my $class = shift;
    return $class->__selectSingle( sprintf q|
      SELECT max(value) FROM %s
    |, $class->tableName() )->[0];
  },

  # Overrides OP::Persistence:
  _updateRecord => sub($) {
    my $self = shift;
    my $class = $self->class();

    my $rows = $class->write(
      $self->_updateRowStatement()
    );

    return false unless $rows;

    #
    # We are inside of a transaction right now, so this is legit
    #
    my $table = $class->tableName();

    my $results = $class->__selectSingle( sprintf q|
      select id, modulo from %s where id = ( select max(id) from %s )
    |, $table, $table );

    $self->setId($results->[0]);
    $self->setModulo($results->[1]);

    return $rows;
  },

  # Overrides OP::Persistence:
  _updateRowStatement => sub($) {
    my $self = shift;
    my $class = $self->class();

    my $attributes = OP::Array->new(
      $class->attributes()
    );

    my $table = $class->tableName();

    #
    # big honkin sprintf
    #
    return sprintf( q|
        INSERT INTO %s ( %s )
          SELECT %s
          FROM %s
        ON DUPLICATE KEY
          UPDATE %s;
      |,
      $table,
      $attributes->join(', '),
      $self->_quotedValues()->join(", "),
      $table,
      $attributes->collect( sub {
        yield "$_ = values($_)";
      } )->join(",\n            ")
    );
  },

  # Overrides OP::Persistence:
  _newId    => sub($) { 0 }, # Kind of a hack; ID comes from MySQL
};
