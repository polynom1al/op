#
# File: OP/Object.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Object;

=pod

=head1 NAME

OP::Object - Abstract object class

=head1 DESCRIPTION

Base abstract object class for the OP framework. Extends L<OP::Class> with
a constructor, getters, and setters.

See L<OP::Array>, L<OP::Hash>, L<OP::Example> for concrete implementations.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > OP::Object

=head1 PUBLIC CLASS METHODS

=cut

use strict;
use warnings;

use Clone qw| clone |;
use Error qw| :try |;
use Perl6::Subs;

use OP::Type;
use OP::Enum::Bool;
use OP::Exceptions;

use base qw| OP::Class |;

our $AUTOLOAD;
our @EXPORT;

=pod

=over 4

=item * $class->new()

Returns a new object instance. Optionally accepts a hash or hash ref
for use as a prototype object.

  #
  # File: Example.pm
  #
  # Implement a concrete class based on OP::Object:
  #
  use OP::Class;

  create "OP::Example" => {
    __BASE__ => "OP::Object"
  };

Meanwhile, in caller:

  #!/bin/env perl

  #
  # File: somecaller.pl
  #
  # New empty object:
  #
  my $obj = OP::Example->new();

  #
  # New object from an even list:
  #
  my $objFromList = OP::Example->new(
    foo => "whiskey",
    bar => "tango"
  );

  #
  # New object from HASH ref:
  #
  my $objFromRef = OP::Example->new( {
    foo => "whiskey",
    bar => "tango"
  } );

=cut

method new(OP::Class $class: *@args)  {
  my $hash;

  if ( @args == 0 ) {
    #
    # No arguments provided, so start with an empty hash
    #
    $hash = { };

  } elsif ( @args == 1 ) {
    #
    # Single argument was provided:
    #
    if ( ref $args[0] ) {
      #
      # Single reference arg provided, which should walk like a HASH:
      #
      $hash = shift @args;

      throw OP::InvalidArgument(
        "In $class->new(...), arg was not HASH-like"
      ) if !UNIVERSAL::isa($hash, "HASH");
    } else {
      #
      # Garbage in?
      #
      my $caller = caller();

      throw OP::InvalidArgument(
        "BUG (Check $caller): "
        . "In $class->new(...), args should be hash, hashref, or nothing"
      );
    }

  } else {
    #
    # Unreferenced list received; make a HASHREF from it:
    #
    my %hash = @args;

    $hash = \%hash;
  }

  #
  #
  #
  my $assertions = $class->get('ASSERTS');

  if ( $assertions ) {
    #
    # We'll make a clean, new self and assign it later:
    #
    my $sanitized = bless { }, $class;

    # 
    # Class assertions were provided;
    # use provided value, or fall back to default
    # 
    for my $key ( keys %{ $assertions } ) {
      my $type = $assertions->{$key};

      my $value = $hash->{$key};

      #
      # if optional() was specified and there's no value,
      # populate sanitized hash with undef and move on:
      #
      if ( !defined $value && $type->optional() ) {
        $sanitized->set($key, undef);

        next;
      }

      #
      # If these tests are failing in the constructor, the caller
      # probably did not send the proper (or any args).
      #
      my $keyLabel = join("::", $class, $key);

      if ( defined $value ) {
        $type->test($keyLabel, $value);

        $sanitized->set($key, ref($value) ? clone($value) : $value);

      } else {
        #
        # fall back to default
        #
        my $default = $type->default();

	#
	# test the default value, because it might be invalid on purpose
	# (that is, callers of this class might need to provide an
	# allowed value for this attribute in the constructor)
	#
        $type->test($keyLabel, $default);

        $sanitized->set($key, ref($default) ? clone($default) : $default);
      }
    }

    #
    # Perl reference magic
    #
    $hash = $sanitized;
  } else {
    bless $hash, $class;
  }

  $hash->_init();

  return $hash;
};


=pod

=item * $class->proto()

Constructor method. Returns a new instance of self, populated with
default values. The returned object may contain undefined values which
must be populated before calling C<save()>.

=cut

method proto (OP::Class $class:) {
  my $self = bless { }, $class;

  my $asserts = $class->asserts();

  for my $attr ( $class->attributes() ) {
    my $type = $asserts->{$attr};

    my $default = $type->default();

    next if !defined($default);

    try {
      $self->set($attr, $default);
    } catch OP::AssertFailed with {
      my $error = $_[0];

      warn "Prototype warning (possibly harmless): $error";
    };
  }

  return $self;
};


=pod

=item * $class->attributes()

Returns a flat list of allowed attributes, if any, for objects of
this class. Includes any attribute names in C<__baseAsserts()>.

  my @keys = $class->attributes();

=cut

method attributes(OP::Class $class:) {
  if ( $class->class() ) {
    $class = $class->class();
  }

  return sort keys %{ $class->asserts() };
};


=pod

=item * $class->isAttributeAllowed($key)

Returns true if the received key is a valid attribute for instances of
the current class, otherwise warns to STDERR and returns false.

  #
  # File: Example.pm
  #
  # Create a new class with two attrs, "foo" and "bar"
  #
  my $class = "OP::Example";

  create $class => {
    foo => OP::Str->assert(),

    bar => OP::Int->assert(),

    # ...
  };

Meanwhile, in caller...

  #!/bin/env perl

  #
  # File: somecaller.pl
  #
  # Check for allowed attributes:
  #
  for ( qw| foo bar rebar | ) {
    next if !$class->isAttributeAllowed($_);

    # ...
  }

  #
  # Expected output is warning text to the effect of:
  #
  # BUG IN CALLER: "rebar" is not a member of class "OP::Example"
  #

=cut

method isAttributeAllowed(OP::Class $class: Str $key) {
  my $asserts = $class->asserts();

  if ( keys %{ $asserts } ) {
    if ( exists $asserts->{$key} ) {
      return true;
    } else {
      my $caller = caller();
      warn "BUG (Check $caller): \"$key\" is not a member of \"$class\"";
      return false;
    }
  } else {
    return true;
  }
};


=pod

=item * $class->asserts()

Abstract method, implemented by subclasses to returns an OP::Hash of
assertion objects, including any base assertions which may be present.

  my $asserts = $class->asserts();

=cut

method asserts(OP::Class $class:) {
  throw OP::ClassIsAbstract(
    "Abstract class $class will never have assertions"
  );
};


=pod

=item * $class->assert()

Abstract method, implemented by subclasses to return an assertion object.

Returns a pre-made OP::Type object with subtypes for the named
datatype. See "Concrete Classes" in L<OP> for a list of types which may
be asserted.

  create "OP::Example" => {
    someStr     => OP::Str->assert(
      ::optional(),
      ::default("Foo Bar!")
    ),

    someInt     => OP::Int->assert( ::optional() ),
    someFloat   => OP::Float->assert( ::optional() ),
    someDouble  => OP::Double->assert( ::optional() ),
    someBool    => OP::Bool->assert( ::default(false) ),

    # ...
  };

To enforce a range of allowed values, use the desired values as arguments:

  create "OP::Example" => {
    foo => OP::Str->assert(qw| alpha bravo cthulhu |);

    ...
  };

If the range of allowed values should be looked up from some external
source at runtime (rather than load time), provide an anonymous function
(Perl C<sub{}> block or C<CODE> ref).

This lets the range of allowed values change through the lifetime of
the application process, based on whatever the function returns (as
opposed to using a static list, which is loaded at "use" time and doesn't
adapt to changing data.)

The function provided should return an unreferenced array of allowed
values.

 ...

  create "OP::Example" => {
    #
    # Always check against a live datasource:
    #
    someId => OP::Str->assert( sub { OP::Example->allIds() } ),

    ...
  };

Instance variables containing complex data structures, objects, or
pointers to external objects follow the same basic form as simple assertions.

The values for L<OP::Array> and L<OP::Hash> attributes are stored in
linked tables, which OP creates and manages.

L<OP::ExtID>, which is a simple pointer to an external object, is
generally a more maintainable approach than inline L<OP::Array> and
L<OP::Hash> elements, and also provides the best performance.

=cut

method assert(OP::Class $class: *@rules) {
  throw OP::ClassIsAbstract(
    "You may not assert attributes for abstract class $class"
  );
};


method elementClass(OP::Class $class: Str $key) {
  #
  # No-op is fine for abstract method
  #
};


=pod

=back

=head1 PRIVATE CLASS METHODS

=head2 Class Callback Methods

=over 4

=item * $class->import()

Callback method invoked when callers C<use> this package. Provides caller
with Types and Bools.

=cut

method import(OP::Class $class: *@what) {
  my $caller = caller();

  #
  # deep magics
  #
  # install the bare "assert" keyword inside of caller
  #
  eval qq/
    package $caller;

    use OP::Type;
    use OP::Enum::Bool;
  /;

  my $asserts = $class->get("ASSERTS");

  return if !$asserts;

  for my $key ( keys %{ $asserts } ) {
    my $type = $asserts->{$key};

    next if !ref($type)
      || (
        !UNIVERSAL::isa($type, 'HASH')
        && !UNIVERSAL::isa($type, 'ARRAY')
      );
        # ref($type->{$key}) !~ /Hash|Array/i;

    $class->elementClass($key);
  }
};

=pod

=item * $class->__baseAsserts()

Abstract method.

Asserts are not inherited by subclasses, unless defined in the hash
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

=cut

method __baseAsserts(OP::Class $class:) {
  throw OP::ClassIsAbstract(
    "Abstract class $class has no base asserts"
  );
};

method __assertClass(OP::Class $class:) {
  my $assertClass = $class->get("__assertClass");

  if ( !defined $assertClass ) {
    $assertClass = $class;
    $assertClass =~ s/.*\:\:/OP::Type::/;

    #
    # Dynamically allocate a Type subclass
    # 
    do {
      no strict "refs";

      @{"$assertClass\::ISA"} = qw| OP::Type |;
    };

    $class->set("__assertClass", $assertClass);

    $assertClass->set("objectClass", $class);
  }

  return $assertClass;
};

=pod

=back

=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $self->get($key)

Get the received instance variable. Very strict about input enforcement.

If using assertions, OP *DIES* if the key is invalid!

=cut

method get(Str $key) {
  my $class = $self->class();

  if ( $class ) {
    throw OP::RuntimeError("$key is not a member of $class")
      if !$class->isAttributeAllowed($key);

    return $self->{$key};
  } else {
    return $self->SUPER::get($key);
  }
};

=pod

=item * $self->set($key, $value)

Set the received instance variable. Very strict about input enforcement.

If using assertions, OP *DIES* on purpose here if key or value are invalid.

=cut

method set(Str $key, *@value) {
  my $class = $self->class();

  if ( $class ) {
    throw OP::RuntimeError("Extra args received by set()")
      if scalar(@value) > 1;

    throw OP::RuntimeError("$key is not a member of $class")
      if !$class->isAttributeAllowed($key);

    my $type = $class->asserts()->{$key};

    throw OP::AssertFailed("Type for $key failed")
      if $type && !$type->test($key, $value[0]);

    $self->{$key} = $value[0];
  } else {
    return $self->SUPER::set($key,@value);
  }

  return true;
};


=pod

=item * $self->clear()

Removes all items, leaving self with zero elements.

  my $object = OP::Example->new(
    foo => "uno",
    bar => "dos"
  );

  print $object->size(); # 2
  print "\n";

  $object->clear();

  print $object->size(); # 0
  print "\n";

=cut

method clear() {
  %{ $self } = ( );

  return $self;
};


=pod

=item * $self->class()

Object wrapper for Perl's built-in ref() function

=cut

method class() {
  return ref($self);
};


=pod

=item * $self->value()

Returns self's value as a native data type, ie dereferences it

=cut

method value() {
  return %{ $self };
};


=pod

=back

=head2 AUTOLOADED

=over 4

=item * $self->set<Attribute>($value)

AUTOLOADed setter method. Set the attribute named in the message to the
received value. Does lcfirst on the attribute name.

Performs value checking and sanitizing (a good reason to use the setter!)

  $self->setFoo("bario")

=item * $self-><Attribute>()

AUTOLOADed getter method. Returns the value for the received attribute.

  $self->setFoo("bario");

  my $value = $self->foo(); # returns "bario"

=item * $self->delete<Attribute>()

AUTOLOADed key deletion method. Removes the named attribute from the
working object. Performs lcfirst on the attribute named in the message.

  $self->setFoo("bario");
  $self->foo(); # returns "bario";

  $self->deleteFoo();
  $self->foo(); # returns undef

=cut

method AUTOLOAD(*@args) {
  my $message = $AUTOLOAD;
  $message =~ s/.*:://;

  return if $message eq 'DESTROY';

  my $class = $self->class();

  if ( !$class ) {
    $class = $self;

    my $value = $class->get($message);

    if ( !defined $value ) {
      my ($package, $filename, $line) = caller;

      throw OP::RuntimeError(
        "BUG (Check $package:$line): Class var \@$class\::$message is undefined"
      );
    }

    return $value;
  }

  if ($message =~ /^[Ss]et(\w+)/) {
    my $attributeName = lcfirst($1);

    #
    # set() will perform attribute tests
    #
    if ( scalar(@args > 1) ) {
      return $self->set($attributeName, \@args);
    } else {
      return $self->set($attributeName, $args[0]);
    }
  } elsif ($message =~ /^[Dd]elete(\w+)/) {
    my $attributeName = lcfirst($1);

    return if !$class->isAttributeAllowed($attributeName);

    return delete $self->{$attributeName};
  } elsif ($message =~ /^[Gg]et(\w+)/) {
    my $attributeName = lcfirst($1);

    #
    # get() will perform attribute tests
    #
    return $self->get($attributeName);
  } else {
    return $self->get($message);
  }
};


=pod

=back

=head1 PRIVATE INSTANCE METHODS

=over 4

=item * $self->_init();

Abstract callback method invoked after object creation (called from new()).

Override in subclass to handle additional logic if needed.

=cut

method _init() {
  return true;
};


=pod

=back

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Object.pm#13 $

=cut

true;
