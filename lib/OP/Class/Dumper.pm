#
# File: OP/Class/Dumper.pm
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

OP::Class::Dumper - Class and object introspection mix-in

=head1 PUBLIC CLASS MIX-IN METHODS

=over 4

=cut

package OP::Class::Dumper;

use strict;
use warnings;

use OP::Enum::Bool;
use Perl6::Subs;
use JSON::Syck;
use YAML::Syck;

$YAML::Syck::UseCode  = true;
$YAML::Syck::LoadCode = true;
$YAML::Syck::DumpCode = true;

=pod

=item * $class->members()

Return an OP::Array containing the names of all valid messages (symbols)
in this class.

=cut

method members(OP::Class $class:) {
  return OP::Array->new(OP::Class::members($class));
};

=pod

=item * $class->membersHash()

Return an OP::Hash containing the CODE refs of all valid messages in
this class, keyed on message (symbol) name.

=cut

method membersHash(OP::Class $class:) {
  return OP::Hash->new(OP::Class::membersHash($class));
};

=pod

=item * $class->asserts()

Returns the OP::Hash of attribute assertions for this class, including
any base assertions which may be present.

Overrides the abstract method from OP::Class with a concrete implementation
for non-abstract classes.

  my $asserts = $class->asserts();

=cut

method asserts(OP::Class $class:) {
  my $asserts = $class->get('ASSERTS');

  if ( !$asserts ) {
    my %baseAsserts = %{ $class->__baseAsserts() };

    $asserts = OP::Hash->new(%baseAsserts); # Re-reference

    $class->set('ASSERTS', $asserts);
  }

  return $asserts;
};

=pod

=item * $class->__baseAsserts()

Returns a clone of the OP::Hash of base assertions for this class.
Types are not inherited by subclasses, unless defined in the hash
returned by this method. Override in subclass to provide a hash of
inherited assertions.

Unless implementing a new abstract class that uses special keys,
__baseAsserts() does not need to be used or modified. Concrete classes
should just use inline assertions as per the examples in L<OP::Type>.

C<__baseAsserts()> may be overridden as a C<sub{}> or as a class variable.

Using a C<sub{}> lets you extend the parent class's base asserts, or use
any other Perl operation to derive the appropriate values:

  create "OP::Example" => {
    #
    # Inherit parent class's base asserts, tack on "foo"
    #
    __baseAsserts => method(OP::Class $class:) {
      my $base = $class->SUPER::__baseAsserts();

      $base->{foo} = OP::Str->assert();

      return $base;
    },

    # ...
  };

One may alternately use a class variable to redefine base asserts,
overriding the parent:

  create "OP::Example" => {
    #
    # Statically assert two base attributes, "id" and "name"
    #
    __baseAsserts => {
      id   => OP::Int->assert(),

      name => OP::Str->assert()
    },

    # ...
  }

To inherit no base assertions:

  create "OP::RebelExample" => {
    #
    # Sometimes, parent doesn't know best:
    #
    __baseAsserts => { },

    # ...
  }

Overrides the abstract method from OP::Class with a concrete implementation
for non-abstract classes.

=cut

method __baseAsserts(OP::Class $class:) {
  my $asserts = $class->get("__baseAsserts");

  if ( !defined $asserts ) {
    $asserts = OP::Hash->new();

    $class->set("__baseAsserts", $asserts);
  }

  return( clone $asserts );
};

=pod

=back

=head1 PUBLIC INSTANCE MIX-IN METHODS

=over 4

=item * $self->sprint(), $self->toYaml()

Object introspection method.

Returns a string containing a YAML representation of the current object.

  $r->content_type('text/plain');

  $r->print($object->toYaml());

=cut

method toYaml() {
  if ( !$self->isa("OP::Hash") ) {
    return YAML::Syck::Dump($self);
  }

  return YAML::Syck::Dump($self->escape);

  # return YAML::Syck::Dump($self);
};

method sprint() {
  return $self->toYaml();
}

=pod

=item * $self->print()

Prints a YAML representation of the current object to STDOUT. 

=cut

method print() {
  return CORE::print($self->sprint());
};


=pod

=item * $self->prettySprint();

Returns a nicely formatted string representing the contents of self

=cut

method prettySprint() {
  my $str = "";

  print "-----\n";
  for my $key ( $self->class()->attributes() ) {
    my $prettyKey = $self->class()->pretty($key);

    my $value = $self->get($key) || "";

    print "$prettyKey: $value\n";
  }
};


=pod

=item * $self->prettyPrint();

Prints a nicely formatted string representing self to STDOUT

=cut

method prettyPrint() {
  return CORE::print($self->prettySprint());
};

method escape() {
  my $asserts = $self->class->asserts;

  my $class = $self->class;

  my $escaped;

  if ( $self->isa("OP::Hash") ) {
    $escaped = OP::Hash->new;

    $self->each( sub {
      if ( UNIVERSAL::isa($self->{$_},"OP::Object") ) {
        $escaped->{$_} = $self->{$_}->escape();
      } else {
        $escaped->{$_} = $self->{$_};
      }
    } );
  } elsif ( $self->isa("OP::Array") ) {
    $escaped = $self->collect( sub {
      if ( UNIVERSAL::isa($_,"OP::Object") ) {
        OP::Array::yield($_->escape());
      } else {
        OP::Array::yield($_);
      }
    } );
  } elsif (
    $self->isa("OP::Scalar")
    || $self->isa("OP::DateTime")   # Scalar-like
    || $self->isa("OP::EmailAddr")  # Scalar-like
  ) {
    $escaped = "$self";
  } else {
    $escaped = $self;
  }

  return $escaped;
};

method toJson() {
  return JSON::Syck::Dump($self->escape());
};

=pod

=back

=head1 SEE ALSO

This file is part of L<OP>.

=cut

true;
