#
# File: OP/Persistence/Async.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Persistence::Async;

use strict;
use warnings;

use Error qw| :try |;
use Perl6::Subs;
use OP::Array qw| yield emit |;
use OP::Bool;
use OP::Enum::Bool;
use OP::Hash;
use OP::Recur qw| snooze break |;
use OP::Redefines;
use OP::Persistence;
use POE qw| Wheel::Run |;

use base qw| Exporter |;

our @EXPORT_OK = qw| finish transmit convey |;

#
# Parallel arrays for queries: ($class, $query, $sub);
#
my $classes   = OP::Array->new;
my $queries   = OP::Array->new;
my $subs      = OP::Array->new;
my $callbacks = OP::Array->new;

#
# Array of boolean objects, true if session still executing
#
my $running = OP::Array->new;

#
#
#
my $kernel = POE::Kernel->new;

#
# Max concurrency
#
my $maxWorkers  = 4;

#
# Main dispatch loop - runs any pending query in a
# new POE Wheel, and makes sure we stay below max
# concurrency. Caller must cede to this loop in order
# for anything to happen.
#
do {
  my $recur = OP::Recur->new;

  $recur->every(.01);

  $recur->coloop( sub {
    return if $subs->isEmpty;

    $running = $running->collect(
      sub( OP::Bool $done ) { yield $done if !$done }
    );

    return if $running->size > $maxWorkers;

    my $class    = $classes->shift;
    my $query    = $queries->shift;
    my $sub      = $subs->shift;
    my $callback = $callbacks->shift;

    $running->push( __queryInSubproc($class,$query,$sub,$callback) );
  } );
};

sub __queryInSubproc(OP::Class $class, Str $query, Code ?$sub, Code ?$callback) {
  return convey(
    sub {
      my $sth = $class->query($query);

      &{ $sub }($sth) if $sub;
    },
    $callback
  );
};

sub convey(Code $sub, Code ?$callback) {
  my $done = OP::Bool->new(false);

  my $onStart = sub {
    my $child = POE::Wheel::Run->new(
      Program      => $sub,
      StdoutEvent  => "onChildStdout",
      StderrEvent  => "onChildStderr",
      CloseEvent   => "onChildClose",
    );

    $_[KERNEL]->sig_child( $child->PID, "onChildSignal" );
    $_[HEAP]{children_by_wid}{$child->ID}  = $child;
    $_[HEAP]{children_by_pid}{$child->PID} = $child;
  };

  my $onChildSignal = sub {
    my $child = delete $_[HEAP]{children_by_pid}{$_[ARG1]};

    ${ $done } = true;

    return if !defined $child;

    delete $_[HEAP]{children_by_wid}{$child->ID};
  };

  my $onChildStdout = sub {
    my ( $line, $wid ) = @_[ARG0,ARG1];

    if ( $line =~ /^OP_XMIT:(.*)/ ) {
      my $data = JSON::Syck::Load($1);

      &{ $callback }($data);
    } else {
      my $child = $_[HEAP]{children_by_wid}{$wid};

      print "<". $child->PID ."> $line\n";
    }
  };

  POE::Session->create(
    inline_states => {
      _start => $onStart,
      onChildStdout => $onChildStdout,
      onChildStderr => \&onChildStderr,
      onChildClose  => \&onChildClose,
      onChildSignal => $onChildSignal,
    }
  );

  $kernel->run_one_timeslice;

  return $done;
};

sub coquery(OP::Class $class, Str $query, Code $sub, Code $callback) {
  $classes->push($class);
  $queries->push($query);
  $subs->push($sub);
  $callbacks->push($callback);
};

sub transmit ( *@data ) {
  for ( @data ) {
    print "OP_XMIT:";
    print JSON::Syck::Dump($_);
    print "\n";
  }
};

sub finish {
  Coro::cede;

  my $recur = OP::Recur->new;

  $recur->every(.01);

  $recur->loop( sub {
    Coro::cede;

    if ( $kernel->get_event_count ) {
      $kernel->run_one_timeslice;
    }

    $running = $running->collect(
      sub ( OP::Bool $done ) { yield $done if !$done }
    );

    break if $running->isEmpty;
  } );

  #
  # Let any remaining POE sessions finish:
  $kernel->run;
};

sub onChildStdout {
  my ( $line, $wid ) = @_[ARG0,ARG1];

  my $child = $_[HEAP]{children_by_wid}{$wid};

  print "<". $child->PID ."> $line\n";
};

sub onChildStderr {
  my ( $line, $wid ) = @_[ARG0,ARG1];

  my $child = $_[HEAP]{children_by_wid}{$wid};

  print STDERR "!!! <". $child->PID ."> $line\n";
};

sub onChildClose {
  my ( $wid ) = $_[ARG0];

  my $child = $_[HEAP]{children_by_wid}{$wid};

  if ( !defined $child ) {
    # print "WID $wid closed all pipes\n";

    return;
  }

  # print "PID ". $child->PID ." closed all pipes\n";

  delete $_[HEAP]{children_by_pid}{$child->PID};
  delete $_[HEAP]{children_by_wid}{$child->ID};
};

package OP::Persistence;

use strict;
use warnings;

*coquery = \&OP::Persistence::Async::coquery;

true;

__END__

=pod

=head1 NAME

OP::Persistence::Async - Non-blocking statement handle access for OP classes

=head1 DESCRIPTION

L<POE::Wheel::Run> is used for handling database access in a forked
background process. Unlike most other modules using POE for DB access,
this module foregoes the marshaling of (potentially huge) data sets and
the plethora of delegate methods which usually come with the territory
of asynchronous DB access.

Instead, this mix-in exposes each query's statement handle (C<DBI::st>
object, aka C<$sth>) directly to the caller, allowing for more
memory-efficient handling of data, all while using the usual DBI method
calls which Perl developers are familiar with.

The C<coquery> class method launches a query in the background. The
C<finish> function waits for any pending workers to finish up.
C<transmit> pipes data structures from child process to the parent's
callback sub.

=head1 METHODS

=over 4

=item * $class->coquery(Str $query), finish

B<INSERT/UPDATE Handler> - Executes the received query in a background
process. For INSERT and UPDATE queries, just provide the query as an arg.

  use OP;

  # ...

  $class->coquery(
    sprintf('update %s set foo = 42', $class->tableName)
  );

  # Wait for workers to finish
  finish;


=item * $class->coquery(Str $query, Code $sub), finish

B<SELECT Handler> - Executes the received query in a background process,
handing off the statement handle to the received sub.

  $class->coquery(
    sprintf('select name from %s', $class->tableName),
    sub(DBI::st $sth) {
      while( my ( $name ) = $sth->fetchrow_array ) {
        print "Have name: $name\n";

        #
        # Do something with $class, maybe some synchronous queries
        # in this subprocess.
        #
      }
    }
  );

  finish;


=item * $class->coquery(Str $query, Code $sub, Code $callback), transmit($value, [$value, ...]), finish

B<SELECT Handler with Callback> - Executes the received query in a
background process, handing off the statement handle to the received
sub. Hand off any transmitted data structures to the received callback
sub, which runs in the parent process.

The C<transmit> function encodes any received data structures, and
propagates up to the parent.

  $class->coquery(
    sprintf('select id, name from %s', $class->tableName),
    sub(DBI::st $sth) {
      while( my $hash = $sth->fetchrow_hashref ) {
        print "$$ - Child is transmitting $hash->{name}\n";

        transmit $hash;
      }
    },
    sub(Hash $hash) {
      print "$$ - Parent process received $hash->{name}\n";
    }
  );

  finish;

=back

=head1 FUNCTIONS

=over 4

=item * finish

Waits for any pending queries to finish execution. Does not block
execution of other POE or Coro threads.

=item * transmit($value, [$value, ...])

Propagates the received values, to be collected within the parent
process's optional callback sub. Will not work for GLOB, CODE, or
circular references.

=item * convey($fromSub, [$toSub])

Run the received CODE block ($fromSub) in a subprocess, and reap any
transmitted results using the received callback in the parent process.

  use OP;

  convey(
    # $fromSub:
    sub {
      transmit "Hello from $$...";
      sleep 3;
      transmit "And hello again (from $$ of course)...";
    },

    # $toSub:
    sub(Str $str) {
      print "$$ received string: $str\n";
    }
  );

  finish;

  #
  # 26464 received string: Hello from 26466...
  # 26464 received string: And hello again (from 26466 of course)...
  #

=back

=head1 SEE ALSO

This file is part of L<OP>.

=cut
