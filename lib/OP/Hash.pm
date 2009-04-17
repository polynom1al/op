#
# File: OP/Hash.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Hash;

use strict;
use warnings;

use OP::Array qw| yield |;
use OP::Class qw| true false |;

use base qw| OP::Class::Dumper OP::Object |;

use Error qw| :try |;
use Perl6::Subs;
use Hash::Util;

=pod

=head1 NAME

OP::Hash

=head1 DESCRIPTION

Extends L<OP::Object> to handle Perl HASH refs as OP Objects. Provides
constructor, getters, setters, "Ruby-esque" collection, and other methods
which one might expect a Hash table object to respond to.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > L<OP::Object> > OP::Hash

=head1 SYNOPSIS

  use OP::Hash;

  my $hash = OP::Hash->new();

  my $hashFromNonRef = OP::Hash->new(%hash); # Makes new ref

  my $hashFromRef = OP::Hash->new($hashref); # Keeps orig ref

=head1 PUBLIC CLASS METHODS

=over 4

=item * $class->assert(*@rules)

Return a new OP::Type::Hash instance.

Hash() simply specifies that the attribute's value is a free-form
hashtable. No further validation will be performed against the value,
other than to make sure it's a HASH (or L<OP::Hash>) reference.

Hash() is intended for cases where arbitrary, extrinsic hashtable-
formatted data, with keys not known in advance, needs to be stored
within an object. It should not be used as a replacement for ExtID()
linked to a properly modeled class.

The key/value pairs in the stored hash live in a dynamically subclassed
linked table, with foreign key constraints against the parent table.

  #
  # File: Example.pm
  #
  use OP;

  create "OP::Example" => {
    inlineHash => OP::Hash->assert()
  };

In caller:

  #!/bin/env perl
  #
  # File: somecaller.pl
  #

  use strict;
  use warnings;

  use OP::Example;

  my $example = OP::Example->spawn("Inline Hash Example");

  $example->setInlineHash({ foo => bar });

  $example->save();

=cut

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isHash, @rules
  );

  $parsed{default} ||= { };
  $parsed{columnType} ||= 'TEXT';

  return $class->__assertClass()->new(%parsed);
}


=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $hash->collect($sub), yield(item, [item, ...]), emit(item, [item...])

Ruby-esque key iterator method. Returns a new L<OP::Array>, containing
the yielded results of calling the received sub for each key in $hash.

$hash->collect is shorthand for $hash->keys->collect, so you're really
calling C<collect> in L<OP::Array>. C<yield> and C<emit> are exported
by L<OP::Array>. Please see the documentation for OP::Array regarding
usage of C<collect>, C<yield>, and C<emit>.

  #
  # For example, quickly wrap <a> tags around array elements:
  #
  my $tagged = $object->collect( sub {
    print "Key $_ is $object->{$_}\n";

    emit "<a name=\"$_\">$object->{$_}</a>";
  } );

=cut

method collect(Code $sub) {
  return $self->keys()->collect($sub);
};


=pod

=item * $self->each($sub)

List iterator method. Runs $sub for each element in self; returns true
on success.

  my $hash = OP::Hash->new(
    foo => "uno",
    bar => "dos",
    rebar => "tres"
  );

  $hash->each( sub {
    print "Have key: $_, value: $hash->{$_}\n";
  } );

  #
  # Expected output:
  #
  # Have key: foo, value: uno
  # Have key: bar, value: dos
  # Have key: rebar, value: tres
  #

=cut

method each(Code $sub) {
  return $self->keys()->each($sub);
}

=pod

=item * $self->keys()

Returns an L<OP::Array> object containing self's alpha sorted keys.

  my $hash = OP::Hash->new(foo=>'alpha', bar=>'bravo');

  my $keys = $hash->keys();

  print $keys->join(','); # Prints out "bar,foo"

=cut

method keys() {
  return OP::Array->new(sort keys %{ $self });
}


=pod

=item * $self->values()

Returns an L<OP::Array> object containing self's values, alpha sorted by key.

  my $hash = OP::Hash->new(foo=>'alpha', bar=>'bravo');

  my $values = $hash->values();

  print $values->join(','); # Prints out "bravo,alpha"

=cut

method values() {
  return $self->keys()->collect( sub {
    yield $self->{$_};
  } );
}


=pod

=item * $self->set($key,$value);

Set the received instance variable. Extends L<OP::Object>::set to always
use OP::Hash and L<OP::Array> when it can.

  my $hash = OP::Hash->new(foo=>'alpha', bar=>'bravo');

  $hash->set('bar', 'foxtrot'); # bar was "bravo", is now "foxtrot"

=cut

method set(Str $key, *@value) {
  my $class = $self->class();

  #
  # Call set() as a class method if $self was a class
  #
  return $self->SUPER::set($key,@value)
    if !$class;

  my $type = $class->asserts()->{$key};

  return $self->SUPER::set($key,@value)
    if !$type;

  throw OP::InvalidArgument(
    "Too many args received by set(). Usage: set(\"$key\", VALUE)"
  ) if @value > 1;

  my $value = $value[0];

  my $valueType = ref($value);

  my $attrClass = $type->class()->get("objectClass");

  if ( defined($value) && (
    !$valueType || !UNIVERSAL::isa($value, $attrClass)
  ) ) {
    $value = $attrClass->new($value)
  }

  return $self->SUPER::set($key,$value);
}


=pod

=item * $self->size()

Returns the number of key/value pairs in self

=cut

### imported function size() is redef'd
no warnings "redefine";

method size() {
  return scalar( CORE::keys(%{$self}) );
}

use warnings "redefine";
###

=pod

=item * $self->isEmpty()

Returns true if self's size is 0, otherwise false.

=cut

method isEmpty() {
  return $self->size() ? false : true;
}

=pod

=back

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Hash.pm#13 $

=cut

1;
