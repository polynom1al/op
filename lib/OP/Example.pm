#
# File: OP/Example.pm
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

OP::Example - Example of a prototyped class, for testing and playing with

=head1 DESCRIPTION

This package is based on examples found in the documentation for
L<OP::Class> and its associated packages.

See source of this module (Example.pm) for the actual example.

=head1 SYNOPSIS

  use strict;
  use warnings;

  use OP::Example;

  my $ex = OP::Example->spawn("Hello World");

  $ex->setFoo("This ought to work");

  $ex->save("Hello RCS");

  $ex->print();
  
=cut

use OP;

#
# OP Class declarations just invoke the OP::Class::create() function
#
# ie. create($className, $hashRef);
#
create "OP::Example" => {
  #
  # Add a __BASE__ key if you're inheriting from a class other
  # than OP::Node (optional):
  #
  # __BASE__ => "YourNamespace::YourClass"
  #
  # Instance variable support-- just assert a type, and optionally
  # declare allowed and default values.
  #
  # variableName => Type->assert( @AllowedValues, default("YourDefault"))
  #
  # Type can be Array(), Str(), Int(), Float(), Double()
  #
  foo => OP::Str->assert( ::optional() ), # A free-form instance var "foo"

  #
  # Free form with default "ex.". optional() permits undef.
  #
  fob => OP::Str->assert( ::default("ex."), ::optional() ),

  #
  # Array with member assertion! This attribute would allow
  # multiple values:
  #
  beep => OP::Array->assert(
    OP::Str->assert( qw| Bob Larry Sue Sally |, ::default("Bob"))
  ),

  #
  # Declare allowed values and provide default, and override column:
  #
  bar => OP::Str->assert( qw| whiskey tango foxtrot |,
    ::default('whiskey'),
    ::columnType('VARCHAR(64)')
  ),

  #
  # Other data types:
  #
  someInt => OP::Int->assert( qw| 1 3 5 |, ::default(5) ),
  someFloat => OP::Float->assert( qw| 1.0 1.1 1.2 1.3 |, ::default(1.3) ),
  parentId => OP::ExtID->assert( "OP::Example", ::optional() ),
  inlineHash => OP::Hash->assert( ::optional() ),
  someBool => OP::Bool->assert(),

  #
  # Instance or class method support-- just attach a sub { } block.
  #
  rebar => sub {
    my $self = shift;

    print $self->foo();
    print "\n";

    return true;
  },

  #
  # Override an inherited class method:
  #
  # __dbiType => OP::Enum::DBIType::MySQL,

  # __useWeb => false,
};

=pod

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Example.pm#4 $

=cut
