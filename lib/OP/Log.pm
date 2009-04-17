#
# File: OP/Log.pm
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

OP::Log

=head1 DESCRIPTION

Create and access message sinks on the fly. By default, message sinks
are circular L<OP::RRNode> tables.

This class may be used directly, or subclassed for a specific application.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > L<OP::Object> > L<OP::Hash> > L<OP::Node> > OP::Log

Circular table classes are derived from L<OP::RRNode>.

=head1 SYNOPSIS

First, the log needs to be defined in MySQL as a writable datasource:

  use strict;
  use warnings;

  use OP::Log;

  sub createLog {
    my $log = OP::Log->spawn("Alex's Log");

    $log->setNumRows(10);

    $log->save();
  }

  createLog();

Callers may then write to it:

  use strict;
  use warnings;

  use OP::Log;

  my $log = OP::Log->spawn("Alex's Log");

  $log->write("Writing something");

...or record numeric values:

  my $log = OP::Log->spawn("Ben's Log");

  $log->record(432.234);

If more control is needed when saving messages, full object access
is available:

  ...

  use OP::Log;

  my $log = OP::Log->spawn("Alex's Log");

  my $message = $log->newMessage();

  $message->setMessage("Testing at " . scalar(localtime()));
  $message->setState( OP::Enum::State::Crit );
  $message->setValue($$);
  $message->setTimestamp(time());

  $message->save();

The instance method C<messageClass()> returns a L<OP::RRNode> subclass,
a handle for the actual stored messages.

  ...

  my $log = OP::Log->spawn( ... );

  #
  # messageClass() returns the message sink table:
  #
  my $table = $log->messageClass();

  for my $id ( $table->allIds() ) {
    my $message = $table->load($id);

    $message->print();
  }

=head2 Time Series Data

Time series data is directly available through the
C<series()> instance method. This method returns an L<OP::Series>
object.

  ...

  my $log = OP::Log->spawn( ... );

  #
  # Get interpolated time series data, ie { unixtime => value, ... }
  #
  my $series = $log->series($start,$end);

  my $data = $series->cooked();

  $data->each( sub {
    print "At unix time $_, the value was $series->{$_}.\n";
  } );

=cut

use OP;

use OP::Enum::DBIType;
use OP::Enum::Inter;
use OP::RRNode;
use OP::Series;

create "OP::Log" => {
  __numRows  => sub {
    my $class = shift;

    return $class->get("__numRows") || 100;
  },

  __baseAsserts => sub($) {
    my $class = shift;

    my $asserts = OP::Node->__baseAsserts();

    $asserts->{numRows} = OP::Int->assert(
      ::default($class->__numRows())
    );

    $asserts->{name} = OP::Name->assert(
      ::columnType("VARCHAR(20)"),
      ::regex(qr/^\w{1,20}$/),
      ::optional()
    );

    #
    # See _newId and messageClass methods, below
    #
    $asserts->{id} = OP::Str->assert(
      ::columnType("CHAR(6)"),
      ::regex(qr/^\w{6}$/),
      ::optional()
    );

    $asserts->{baseMessageClass} = OP::Str->assert(
      "OP::RRNode",
      ::default("OP::RRNode")
    );

    $asserts->{interpolation} = OP::Int->assert(
      OP::Enum::Inter::Linear,
      OP::Enum::Inter::Spline,
      OP::Enum::Inter::Constant,
      OP::Enum::Inter::Undefined,
      OP::Enum::Inter::None,
      ::default(OP::Enum::Inter::Linear)
    );

    $asserts->{tickSize} = OP::TimeSpan->assert();
    $asserts->{majorTickSize} = OP::TimeSpan->assert();

    return $asserts;
  },

  #
  # These will become table names; can't use GUID for that.
  #
  _newId => sub($) {
    my $self = shift;

    return OP::Utility::randstr();
  },

  #
  # The RRNode backend class is subclassed on the fly.
  #
  # The Class name is SUPER::[id], eg, OP::Log::9dj3J4,
  # which translates to an InnoDB table name of log_9dj3J4
  # in the "op" database
  #
  messageClass => sub($) {
    my $self = shift;

    if ( !$self->exists() ) {
      warn "Log must exist before message class (call log->save first)";
      return undef;
    }

    if ( !$self->{__messageClass} ) {
      my $class = $self->class();
      my $base  = $self->baseMessageClass();

      $self->{__messageClass} = join("::", $class, $self->id());

      create $self->{__messageClass} => {
        __BASE__  => $base,
        __numRows => $self->numRows(),
        name      => OP::Name->assert(::optional()),
      };
    }

    return $self->{__messageClass};
  },

  messageTable => sub($) {
    my $self = shift;

    return $self->messageClass();
  },

  newMessage => sub($) {
    my $self = shift;

    my $messageClass = $self->messageClass();

    if ( !$messageClass ) {
      warn "Could not create message class";
      return undef;
    }

    return $messageClass->new();
  },

  write => sub($$) {
    my $self = shift;
    my $text = shift;

    my $message = $self->newMessage();

    if ( !$message ) {
      warn "Could not create message";
      return undef;
    }

    $message->setMessage($text);
    $message->setTimestamp(time());
    $message->save();

    return $message;
  },

  record => sub($$) {
    my $self = shift;
    my $number = shift;

    my $message = $self->newMessage();

    if ( !$message ) {
      warn "Could not create message";
      return undef;
    }

    $message->setValue($number);
    $message->setTimestamp(time());
    $message->save();

    return $message;
  },

  series => sub($$$) {
    my $self = shift;
    my $startTime = shift;
    my $endTime = shift;

    my $series = OP::Series->new({
      xMin       => $startTime,
      xMax       => $endTime,
      xTickSize  => $self->tickSize(),
      xMajorTickSize => $self->majorTickSize(),
      yInterpolate => $self->interpolation()
    });

    my $sth = $self->messageClass()->query( sprintf q|
      select * from %s where timestamp >= %f and timestamp <= %f
    |, $self->messageClass->tableName(), $startTime, $endTime );

    while ( my $object = $sth->fetchrow_hashref() ) {
      $series->addObject($object);
    }

    return $series;
  },
};

=pod

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Log.pm#7 $

=cut
