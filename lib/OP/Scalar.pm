#
# File: OP/Scalar.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Scalar;

use strict;
use warnings;

use Perl6::Subs;

use OP::Class qw| true false |;

use overload fallback => true,
  '""' => sub { shift->value() },
  'eq' => sub {
    my $first = shift;
    my $second = shift;

    "$first" eq "$second";
  };

use base qw| OP::Class::Dumper OP::Object |;

=pod

=head1 NAME

OP::Scalar

=head1 DESCRIPTION

Scalar object class.

Extends L<OP::Object> to handle Perl scalar values as OP Objects.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > L<OP::Object> > OP::Scalar

=head1 SYNOPSIS

  use OP::Scalar;

  {
    my $scalar = OP::Scalar->new("Hello World\n");
    print "$scalar\n";

    # Hello World
  }

  {
    my $scalar = OP::Scalar->new(5);
    my $result = $scalar + $scalar;
    print "$scalar + $scalar = $result\n";

    # 5 + 5 = 10
  }


=head1 PUBLIC CLASS METHODS

=over 4

=item * $class->new($scalar)

Instantiate a new OP::Scalar. Accepts an optional scalar value as a
prototype object

Usage is cited in the SYNOPSIS section of this document.

=cut

method new(OP::Class $class: Str $self) {
  # throw OP::InvalidArgument("$class instances may not be undefined")
  #  if !defined $self;

  OP::Type::insist $self, OP::Type::isScalar;

  if ( ref($self) && overload::Overloaded($self) ) {
    return bless $self, $class; # ONE OF US NOW
  } elsif ( ref($self) ) {
    throw OP::InvalidArgument(
      "$class->new() requires a non-ref arg, not a ". ref($self)
    );
  } else {
    return bless \$self, $class;
  }
}

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isScalar, @rules
  );

  return $class->__assertClass()->new(%parsed);
}

=pod

=back

=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $self->get()

Abstract method, not implemented.

Delegates to superclass if class method.

=cut

method get(*@args) {
  if ( $self->class() ) {
    my ($package, $filename, $line) = caller(1);

    throw OP::MethodIsAbstract("get() not implemented for scalars"
      ." (you asked for \"". join(", ", @args) ."\" at $package:$line"
    );
  } else {
    return $self->SUPER::get(@args);
  }
}


=pod

=item * $self->set( )

Abstract method, not implemented.

Delegates to superclass if class method.

=cut

method set(*@args) {
  if ( $self->class() ) {
    throw OP::MethodIsAbstract("set() not implemented for scalars");
  } else {
    return $self->SUPER::set(@args);
  }
}


=pod

=item * $self->size()

Object wrapper for Perl's built-in C<length()> function. Functionally the
same as C<length(@$ref)>.

  my $scalar = OP::Scalar->new("Testing");

  my $size = $scalar->size(); # returns 7

=cut

### imported function size() is redef'd
no warnings "redefine";

method size() {
  return $self->length();
}

use warnings "redefine";
###


=pod

=item * $self->isEmpty()

Returns a true value if self contains no values, otherwise false.

  my $array = OP::Scalar->new("");

  if ( $self->isEmpty() ) {
    print "Is Empty\n";
  }

  # Expected Output:
  #
  # Is Empty
  #

=cut

method isEmpty() {
  return ( $self->size() == 0 );
}


=pod

=item * $self->clear()

Truncate self to zero length.

=cut

method clear() {
  ${ $self } = "";

  return $self;
}


=pod

=item * $self->value()

Returns the actual de-referenced value of self. Same as ${ $self };

=cut

method value() {
  return ${ $self };
}


=pod

=item * $self->sprint()

Overrides superclass to sprint the actual de-referenced value of self.

=cut

method sprint() {
  return "$self";
}


=pod

=item * $self->say()

Prints the de-referenced value of self with a line break at the end.

=cut

method say() {
  $self->print();

  print "\n";
}


=back

=head1 SEE ALSO

L<perlfunc>

This file is part of L<OP>.

=head1 REVISION

$Id: $

=cut

true;
