#
# File: OP/Subtype.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Subtype;

=pod

=head1 NAME

OP::Subtype - Subtype rules for L<OP::Type> instances

=head1 DESCRIPTION

Subtypes are optional components which may modify the parameters of
an L<OP::Type>. Subtypes are sent as arguments when calling L<OP::Type>
constructors.

When you see something like:

  foo => OP::Str->assert( ::optional() );

"OP::Str->assert()" was the Type constructor, and "::optional()" was
an Subtype constructor. "foo" was name of the instance variable and
database table column which was asserted.

The class variable %OP::Type::RULES is walked at package load
time, and the necessary rule subclasses are created dynamically.

=head2 SCHEMA ADVISEMENT

Many of these rules affect database schema attributes-- meaning if you
change them after the table already exists, the table will need to be
administratively altered (or moved aside to a new name, re-created,
and migrated). A class's table is created when its package is loaded
for the first time.

For InnoDB tables, OP can handle schema updates programatically, except
in cases of foreign key constraints changing, or columns being renamed.
These exceptions will always require action from a DBA, and it's
advisable to do all schema changes by hand anyway, using carefully reviewed
commands. Always back up the current table before executing an ALTER.

=head2 RULE TYPES

The C<::> preceding these names is more than just a decoration--
it's valid Perl 5 for dispatching messages to the default package,
and has been found to help our source filters do the right thing.

Instance variable assertions may be modified by the following functions:

=head3 ::columnType(Str $type)

Override a database column type. Returns a new
OP::Subtype::columnType instance.

  create "OP::Example" => {
    foo => OP::Str->assert(..., ::columnType("VARCHAR(24)")),

    # ...
  };

=head3 ::default(Any $value)

Set the default value for a given instance variable and database table
column. Returns a new OP::Subtype::default instance.

Unless C<optional()> is given, the default value must also be included
as an allowed value.

  create "OP::Example" => {
    foo => OP::Str->assert("bar", ..., ::default("bar")),

    # ...
  };

=head3 ::min(Int $min)

Specifies the minimum allowed numeric value for a given instance variable.
Returns a new OP::Subtype::min instance.

  create "OP::Example" => {
    foo => OP::Float->assert(..., ::min(0)),

    # ...
  };

=head3 ::minSize(Int $min)

Specifies the minimum length or scalar size for a given instance variable.
Returns a new OP::Subtype::minSize instance.

  create "OP::Example" => {
    foo => OP::Array->assert(..., ::minSize(1)),

    bar => OP::Str->assert(..., ::minSize(24)),

    # ...
  };

=head3 ::max(Int $max)

Specifies the maximum allowed numeric value for a given instance variable.
Returns a new OP::Subtype::max instance.

  create "OP::Example" => {
    foo => OP::Float->assert(..., ::max(255)),

    # ...
  };

=head3 ::maxSize(Int $max)

Specifies the maximum length or scalar size for a given instance variable.
Returns a new OP::Subtype::maxSize instance.

  create "OP::Example" => {
    foo => OP::Array->assert(..., ::maxSize(5)),

    bar => OP::Str->assert(..., ::maxSize(128)),

    # ...
  };

=head3 ::optional()

Permit a NULL (undef) value for a given instance variable. Returns a
new OP::Subtype::optional instance.

  create "OP::Example" => {
    foo => OP::Str->assert(..., ::optional()),

    # ...
  };

=head3 ::regex(Rule $regex)

Specifies an optional regular expression which the value of the given
instance variable must match.  Returns a new OP::Subtype::regex
instance.

  create "OP::Example" => {
    foo => OP::Str->assert(..., ::regex(qr/^bario$/)),

    # ...
  };

=head3 ::serial()

Specify an AUTO_INCREMENT column. This should only be used when asserting
a primary key. Returns a new OP::Subtype::serial instance.

  create "OP::Example" => {
    foo => OP::Str->assert(..., ::serial()),

    # ...
  };

=head3 ::size(Int $size)

Returns a new OP::Subtype::serial instance.

Specify that values must always be of a fixed size. The "size" is the
value obtained through the built-in function C<length()> (string length)
for Scalars, C<scalar(...)> (element count) for Arrays, and C<scalar keys()>
(key count) for Hashes.

  create "OP::Example" => {
    foo => OP::Str->assert(..., ::size(16)),

    bar => OP::Array->assert(..., ::size(5)),

    # ...
  };

=head3 ::sqlValue(Str $statement), ::sqlInsertValue(Str), ::sqlUpdateValue(Str)

Override an asserted attribute's "insert" value when writing to a SQL
database. This is useful if deriving a new value from existing table
values at insertion time. Returns a new OP::Subtype::sqlValue
instance.

C<::sqlInsertValue> and C<::sqlUpdateValue> override any provided value
for ::sqlValue, but only on INSERT and UPDATE statements, respectively.

  create "OP::Example" => {
    foo => OP::Int->assert(...,
      ::sqlValue("(coalesce(max(foo),-1)+1)")
    ),

    # ...
  };

=head3 ::unique()

Specify UNIQUE database table columns. Returns a new
OP::Subtype::unique instance.

  create "OP::Example" => {
    #
    # Your must either specify true or false...
    #
    foo => OP::Str->assert(..., ::unique(true)),

    #
    # ... or specify a name for "joined" combinatory keys,
    # as used in statement UNIQUE KEY ("foo","bar")
    #
    # For example, to make sure bar+foo is always unique:
    #
    bar => OP::Str->assert(..., ::unique("foo")),

    # ...
  };

=head3 ::uom(Str $uom)

Specify an attribute's unit of measurement label. Returns a new
OP::Subtype::uom instance.

  create "OP::Example" => {
    foo => OP::Int->assert(..., ::uom("bytes")),

    bar => OP::Double->assert(..., ::uom("km")),

    # ...
  };

=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $self->value()

Return the scalar value which was provided to self's constructor.

=back

=head1 SEE ALSO

L<OP::Type>

This file is part of L<OP>.

=cut

use Perl6::Subs;

use strict;
use warnings;

use base qw| OP::Class OP::Class::Dumper |;

method new(OP::Subtype $class: *@value) {
  my $value = ( scalar(@value) > 1 ) ? \@value : $value[0];
  
  return bless {
     __value => $value,
  }, $class;
}

method value() {
  return $self->{__value};
}

1;
