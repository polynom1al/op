#
# File: OP.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#

#
# Add any cleanup/shutdown items to the DESTROY method below.
#
# Right now, this just flushes any pending POE Sessions.
#
package OP::Cleanup;

sub new {
  my $class = shift;

  return bless { }, $class;
}

sub DESTROY {
  POE::Kernel->run;
}

package OP;

use strict;
use diagnostics;

use Filter::Simple; # Force stricture and diagnostics in caller...
                    # because that's just the way it's going to be.

FILTER {
  my $filterText = q[ use strict; use diagnostics; use Perl6::Subs; ];

  s/^/$filterText/s;
};

do {
  #
  # Workaround for AutoLoader: Using Coro with OP makes AutoLoader throw
  # undef warnings in the context of a "require" statement when objects
  # without an explicit DESTROY method are culled.
  #
  # To work around this, OP adds an abstract DESTROY method to the the
  # UNIVERSAL package, which all objects in Perl inherit from. The DESTROY
  # method may be overridden as usual on a per-class basis.
  #
  no strict "refs";

  *{"UNIVERSAL::DESTROY"} = sub { };
};

use Encode; # Load this legacy module before all else...
            # or suffer the undefined consequences!

use Error qw| :try |;

#
# Abstract classes
#
use OP::Class qw| create true false |;
use OP::Type;
use OP::Subtype;
use OP::Object;
use OP::Node;

#
# Async functionality
#
use OP::Persistence::Async qw| finish transmit convey |;

#
# Core object classes
#
use OP::Any;
use OP::Array qw| yield emit |;
use OP::Bool;
use OP::Code;
use OP::DateTime;
use OP::Domain;
use OP::Double;
use OP::EmailAddr;
use OP::ExtID;
use OP::Float;
use OP::Hash;
use OP::ID;
use OP::Int;
use OP::IPv4Addr;
use OP::Name;
use OP::Num;
use OP::Recur qw| snooze break |;
use OP::Ref;
use OP::Rule;
use OP::Scalar;
use OP::Str;
use OP::TimeSpan;
use OP::URI;

use base qw| Exporter |;

our @EXPORT = (
  #
  # From OP::Class:
  #
  "create", "true", "false",
  #
  # From OP::Array:
  #
  "yield", "emit",
  #
  # From OP::Recur:
  #
  "snooze", "break",
  #
  # From OP::Persistence::Async:
  #
  "finish", "transmit", "convey",
  #
  # From Error:
  #
  "try", "catch", "with", "finally",
  #
  # Subtyping functions:
  #
  keys %OP::Type::RULES
);

my $cleanup = OP::Cleanup->new;

true;
__END__
=pod

=head1 NAME

OP - Compact Perl 5 class prototyping with object persistence

=head1 VERSION

This documentation is for version B<0.20> of OP.

=head1 STATUS

The usual pre-1.0 warnings apply. Consider this alpha code. It does what
we currently ask of it, and maybe a little more, but it is a work in
progress.

=head1 SYNOPSIS

  use OP;

Using the OP module initializes all built-in object types, and causes
L<strict>, L<diagnostics>, L<OP::Class>, L<OP::Type>, L<Perl6::Subs>,
and L<Error> to be imported by the caller. These may alternately be
imported individually.

=head1 DESCRIPTION

Compact and concise class prototyping, with object persistence.

OP is a Perl 5 dialect for deriving object classes and database
schemas. Apps developed and executed under OP have a greater degree of
formality and consistency than one may be accustomed to seeing in Perl.

This document covers the high-level concepts implemented in OP.

=head1 GETTING STARTED

Subclassing instructions are provided in the "Subclassing" section of
this document, and also outlined in L<OP::Class>.

Instance variable assertions are outlined in L<OP::Type> and L<OP::Subtype>.

See L<Perl6::Subs> for an overview of the Perl 6-style methods used by OP.

See L<Error> for an overview of exception handling in Perl 5.

=head1 PARTIAL FEATURE LIST

=head2 Assertions

Strict and straight-forward control of attribute types (L<OP::Type>),
subtypes (L<OP::Subtype>), and duck-types.

=head2 Prototyping

Inspired by I<Prototype.js> in the JavaScript world, L<OP::Class> provides
the C<create> function, enabling developers to craft database-backed
Perl 5 classes in a compact and concise manner. Complex schemas may be
quickly modeled in code and put to use.

=head2 Persistence

After a class has been prototyped, saving its instantiated objects to
a SQL backing store is as easy as C<$object>->C<save()>.

=head2 Exceptions

Exception handling is brought in from the L<Error> module. C<try>,
C<throw>, and C<catch> are first-class citizens in the OP runtime.

=head2 Formal Methods

Perl 6-style method support is provided by the L<Perl6::Subs> source
filter, and is used extensively throughout OP source and its examples. OP
also implements a generalized subset of Perl 6-derived object types.

=head2 Async Programming

OP provides first-class support for L<Coro> and L<POE>. See L<OP::Recur>
and L<OP::Persistence::Async>.

=head1 FRAMEWORK ASSUMPTIONS

When using OP, a number of things "just happen" by design. Trying
to go against the flow of any of these base assumptions is not
recommended.

=head2 Default Modules

L<strict>, L<warnings>, L<Error>, and L<Perl6::Subs> are on by default.

=head2 Persistent Objects Extend L<OP::Node>

Classes allocated with C<create> will receive an InnoDB backing store,
by virtue of being a subclass of L<OP::Node>. This can be overridden if
needed, see "Inheritance" in L<OP::Class> for details.

Various backing store options are covered in the L<OP::Persistence>
module.

=head2 Default Base Attributes

Unless overridden in C<__baseAsserts>, L<OP::Node> subclasses have
the following baseline attributes:

=over 4

=item * C<id> => L<OP::ID>

C<id> is the primary key at the database table level.

Objects will use a GUID (globally unique identifier) for their id,
unless this behavior is overridden in the instance method C<_newId()>,
and C<__baseAsserts()> overridden to use a non-GUID data type such
as L<OP::Int>.

C<id> is automatically set when saving an object to its backing
store for the time. Modifying C<id> manually is not recommended.

=item * C<name> => L<OP::Name>

OP uses "named objects". By default, C<name> is a human-readable
unique secondary key. It's the name of the object being saved.
Like all attributes, C<name> must be defined when saved, unless asserted
as C<::optional> (see "C<undef> Requires Assertion").

The value for C<name> may be changed (as opposed to C<id>, which should
not be tinkered with), as long as the new name does not conflict with
any objects in the same class when saved.

C<name> may be may be keyed in combination with multiple attributes via
the C<::unique> L<OP::Subtype> argument, which adds InnoDB reference
options to the schema.

  create "My::Class" => {
    #
    # Don't require named objects:
    #
    name => OP::Name->assert(::optional),

    # ...
  };

=item * C<ctime> => L<OP::DateTime>

C<ctime> is the Unix timestamp representing the object's creation
time. OP sets this when saving an object for the first time.

=item * C<mtime> => L<OP::DateTime>

C<mtime> is the Unix timestamp representing the object's last
modified time. OP updates this each time an object is saved.

=back

=head2 C<undef> Requires Assertion

Instance variables may not be C<undef>, unless asserted as
C<::optional>.

Object instances in OP may not normally be C<undef>. Generally, if
a value is not defined, OP currently returns C<undef> rather than an
undefined object instance. This may change at some point.

=head2 Namespace Matters

OP's core packages live under the OP:: namespace. Your classes should
live in their own top-level namespace, e.g. "MyApp::".

=head1 OBJECT TYPES

OP implements the same object class types referred to in L<Perl6::Subs>,
several others which are specific to dealing with a SQL backing store
(e.g. Double, ExtId), as well as datatypes commonly used in network
operations (e.g. EmailAddr, IPv4Addr, URI).

=head2 Usage

OP object types are used when asserting attributes within a class, and are
also suitable for instantiation or subclassing in a self-standing manner.

The usage of these types is not mandatory outside the context of creating
a new class-- OP always returns data in object form, but these object
types are not a replacement for Perl's native data types in general usage,
unless you want them to be.

These modes of usage are shown below, and covered in greater detail
in specific object class docs.

=head3 Subclassing

  use OP;

  create "MyApp::Example" => {
    __BASE__ => "OP::Hash",

  };

or

  package My::Example;

  use strict;
  use warnings;

  use base qw| OP::Hash |;

  1;

=head3 Object Types as Attributes

When defining the allowed instance variables for a class, the C<assert()>
method is used:

  #
  # File: Example.pm
  #
  use OP;

  create "MyApp::Example" => {
    someString => OP::Str->assert(),
    someInt    => OP::Int->assert(),

  };

=head3 As Objects

When instantiating, the class method C<new()> is used, typically with
a prototype object for its argument.

  #
  # File: somecaller.pl
  #
  use strict;
  use warnings;

  use MyApp::Example;

  my $example = MyApp::Example->new(
    name       => "Hello",
    someString => "foo",
    someInt    => 12345,
  );

  $example->save("Saving my first object");

  $example->print();

=head3 In Method Args

To ensure method arguments are always of the appropriate type, specify
the desired type(s) in a L<Perl6::Subs> prototype.

You may specify OP object types or their more general Perl6::Subs
counterparts (with the type names not prefixed by OP::), depending on
how "picky" you want the receiver to be. If a specific OP object type is
specified, the received arg must be of that object type or a subclass (ie,
it must pass the L<UNIVERSAL>C<::isa()> test). The Perl6::Subs equivalent
pseudo-types are designed around Perl 5's native data types, and are
suitable for testing non-objects.

Note that constructors and setter methods accept both native Perl 5 data
types and their OP object class equivalents. The setters will
automatically handle any necessary conversion, or throw an exception if
the received arg doesn't quack like a duck.

Native types are OK for constructors:

  my $example = MyApp::Example->new(
    someString => "foo",
    someInt    => 123,
  );

  #
  # someStr became a string object:
  #
  say $example->someString()->class();
  # "OP::Str"

  say $example->someString()->size();
  # "3"

  say $example->someString();
  # "foo"

  #
  # someInt became an integer object:
  #
  say $example->someInt()->class();
  # "OP::Int"

  say $example->someInt()->sqrt();
  # 11.0905365064094

Native types are OK for setters:

  $example->setSomeInt(456);

  say $example->someInt()->class();
  # "OP::Int"


=head1 ABSTRACT CLASSES & MIX-INS

=head2 L<OP::Class>

B<Abstract "Class" class>

Base package for OP object classes, and lexical prototyping wrapper.

=head2 L<OP::Class::Dumper>

B<Inspect attributes and methods>

Introspection mix-in for classes and objects

=head2 L<OP::Object>

B<Abstract object class>

Extends L<OP::Class> with constructor, getters, setters,
asserts.

=head2 L<OP::Persistence>

B<Object storage and retrieval>

Mix-in for providing backing store support to objects

Specific DBI-type mix-ins are L<OP::Persistence::MySQL> and
L<OP::Persistence::SQLite>. Asynchronous DB access is provided
by the L<OP::Persistence::Async> mix-in.

=head2 L<OP::Node>

B<Abstract stored object class>

Extends L<OP::Hash> and L<OP::Persistence> to form the abstract
base storable object class in OP.

=head2 L<OP::Type>

B<Instance variable typing>

Extends L<OP::Class>. Used by L<OP::Object> subclasses to "assert"
parameters for instance variables and database table columns.

=head2 L<OP::Subtype>

B<Instance variable subtyping>

Extends L<OP::Class>. Used in L<OP::Type> instances to define subtype
restrictions for instance variables and database table columns.

The L<OP::Subtype> module lists the available rule types.

=head1 OBJECT TYPES

These Perl 5 classes represent a generalization of their Perl 6
counterparts, at best, also introducing several object types specific
to dealing with a SQL backing store. OP is not intended to be a Perl
6 implementation at all; there are inconsistencies and cut corners in
the usage of these classes, compared to what Perl 6 will look like. OP
borrows many of these class names for consistency with L<Perl6::Subs>,
and to have less things to remember when coding.

The basic types listed here may be instantiated as objects, or asserted
as inline attributes.

=head2 L<OP::Any>

B<Overloaded, any value>

Extends L<OP::Scalar>. Generally treats the value in a string-like manner,
but may be any Perl 5 value.

=head2 L<OP::Array>

B<List>

Extends L<OP::Object> with Ruby-esque collectors and other array methods.

=head2 L<OP::Bool>

B<Overloaded binary boolean>

Extends L<OP::Scalar>. Implements methods around L<OP::Enum::Bool> in
a transparent manner, where C<true> = 1 and C<false> = 0.

=head2 L<OP::Code>

B<Any CODE reference>

Extends L<OP::Ref>

Differs from the Perl 6 spec, in that it is more of an envelope
for any CODE ref than a base for other classes of executable code.

=head2 L<OP::DateTime>

B<Overloaded time object class>

Extends L<OP::Array>, L<Time::Piece>. Overloaded for numeric comparisons,
stringifies as unix timestamp unless overridden.

=head2 L<OP::Domain>

B<Overloaded domain name object class>

Extends L<OP::Str>. Uses L<Data::Validate::Domain> to verify input.

=head2 L<OP::Double>

B<Overloaded double-precision number>

Extends L<OP::Float>. Perl 5 number. Use L<bignum> to control runtime
precision.  This datatype is specific to OP, and is used when asserting
a double-precision database table column. It is otherwise just a scalar
value.

=head2 L<OP::EmailAddr>

B<Overloaded RFC 2822 email address object class>
  
Extends L<Email::Address>, L<OP::Array>. Uses L<Data::Validate::Email>
to verify input.

=head2 L<OP::ExtID>

B<Overloaded foreign GUID value>

Extends L<OP::ID>. Scalar GUID object. This datatype is specific to OP,
and represents the ID of a foreign object. When asserting a property
backed by an InnoDB table, ExtID sets up foreign key constraints.

=head2 L<OP::Float>

B<Overloaded floating point number>

Extends L<OP::Num> and L<Data::Float>

=head2 L<OP::Hash>

B<Hash reference>

Extends L<OP::Object> with Ruby-esque collectors and other hashtable
methods.

=head2 L<OP::ID>

B<Overloaded primary GUID value>

Extends L<OP::Scalar> and L<Data::GUID>. Represents the primary key
in an object.

=head2 L<OP::Int>

B<Overloaded integer>

Extends L<OP::Num> and L<Data::Integer>

=head2 L<OP::IPv4Addr>

B<Overloaded IPv4 address object class>

Extends L<OP::Str>. Uses L<Data::Validate::IP> to verify input.

=head2 L<OP::Name>

B<Human-readable secondary key>

Extends L<OP::Str>. Represents the secondary key within a class.

=head2 L<OP::Num>

B<Overloaded, any number>

Extends L<OP::Scalar> and L<Scalar::Number>. Implements instance
methods around Perl 5's built-in math functions.

=head2 L<OP::Ref>

B<Any reference value>

Extends L<OP::Any>

=head2 L<OP::Rule>

B<Regex reference (qr/ /)>

Extends L<OP::Ref>

=head2 L<OP::Scalar>

B<Any Perl 5 scalar>

Extends L<OP::Object>. Overloaded with L<overload>.

=head2 L<OP::Str>

B<Overloaded unicode string>

Extends L<OP::Scalar>, L<Mime::Base64>, and L<Unicode::String>.
Implements instance methods around Perl 5's built-in string functions.

=head2 L<OP::TimeSpan>

B<Overloaded time range object class>

Extends L<OP::Scalar>, L<Time::Seconds>. Represents a number of seconds.

=head2 L<OP::URI>

B<Overloaded URI object class>

Extends L<URI>, L<OP::Str>. Uses L<Data::Validate::URI> to verify input.

=head1 CONSTANTS & ENUMERATIONS

=head2 L<OP::Constants>

B<"dot rc" values as constants>

Exposes values from the C<.oprc> file as Perl 5 constants

=head2 L<OP::Enum>

B<C-style enumerated types as constants>

Enumerations are groups of hard-coded constants used internally by OP.

=head1 HELPER MODULES

=head2 L<OP::Utility>

System functions required globally by OP

=head2 L<OP::Exceptions>

Exceptions are subclasses of L<Error> which may be thrown by OP

=head1 EXPERIMENTAL*: INFOMATICS

Experimental classes are subject to radical upheaval, questionable
documentation, and unexplained disappearances. They represent proof of
concept in their respective areas, and may move out of experimental status
at some point.

=head2 L<OP::Log>

B<OP::RRNode factory class>

Generates and loads L<OP::RRNode> subclasses on the fly.

=head2 L<OP::RRNode>

B<Round Robin Database Table>

Objects live in a FIFO table of fixed length.

=head2 L<OP::Series>

B<Cooked OP::RRNode Series Data>

Consolidate L<OP::RRNode> data for easy plotting.

=head1 EXPERIMENTAL: SCHEDULING

=head2 L<OP::Recur>

B<Recurring time specification>

Experimental class for describing recurring points in time.

=head1 EXPERIMENTAL: FOREIGN DB ACCESS

=head2 L<OP::ForeignTable>

B<Any Non-OP Database Table>

Experimental class for using an arbitrary table as a backing store.

=head1 EXPERMENTAL: INTERACTIVE SHELL

=head2 L<OP::Shell>

B<Interactive Perl Shell>

Interactive shell with ReadLine support and lexical persistence.

=head1 SEE ALSO

L<Perl6::Subs>, L<OP::Class>, L<OP::Type>

Object Types from perl6 Synopsis 2:
  - http://dev.perl.org/perl6/doc/design/syn/S02.html

=head1 AUTHOR

  Alex Ayars <pause@nodekit.org>

=head1 COPYRIGHT

  File: OP.pm
 
  Copyright (c) 2009 TiVo Inc.
 
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Common Public License v1.0
  which accompanies this distribution, and is available at
  http://opensource.org/licenses/cpl1.0.txt

=cut
