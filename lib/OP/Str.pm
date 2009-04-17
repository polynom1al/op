#
# File: OP/Bool.pm
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

OP::Bool

=head1 DESCRIPTION

Scalar-backed overloaded object class for strings.

Extends L<OP::Scalar>, L<Mime::Base64>, and L<Unicode::String>.

=head1 SYNOPSIS

  use OP::Bool;

  my $string = OP::String->new("Lorem Ipsum");

=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $self->split($splitRegex)

Object wrapper for Perl's built-in C<split()> function. Functionally the
same as C<split($splitStr, $self)>.

Returns a new OP::Array containing the split elements.

  my $scalar = OP::Scalar->new("Foo, Bar, Rebar, D-bar");

  my $array  = $scalar->split(qr/, */);

  $array->each( sub {
    print "Have item: $_\n";
  } );

  # Have item: Foo
  # Have item: Bar
  # Have item: Rebar
  # Have item: D-bar

=item * chomp, chop, chr, crypt, eval, index, lc, lcfirst, length, rindex, substr, uc, ucfirst

These object methods are wrappers to built-in Perl functions. See
L<perlfunc>.

=back

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Str;

use strict;
use warnings;

use Perl6::Subs;

use base qw| Unicode::String OP::Scalar MIME::Base64 |;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isStr, @rules
  );

  $parsed{columnType}  ||= 'VARCHAR(1024)';
  $parsed{maxSize} ||= 1024;

  return $class->__assertClass()->new(%parsed);
}

method split(Rule $regex) {
  return OP::Array->new( CORE::split($regex, $self) );
}

method chomp() { CORE::chomp($self) }

method chop() { CORE::chop($self) }

method chr() { CORE::chr($self) }

method crypt(Str $salt) { CORE::crypt($self, $salt) }

method eval() { CORE::eval($self) }

method index(Str $substr, Int $pos) { CORE::index($self, $substr, $pos) }

method lc() { CORE::lc($self) }

method lcfirst() { CORE::lcfirst($self) }

method length() { CORE::length($self) }

method rindex(Str $substr, Int $pos) { CORE::rindex($self, $substr, $pos) }

method substr(Int $offset, Int $len) { CORE::substr($self, $offset, $len) }

method uc() { CORE::uc($self) }

method ucfirst() { CORE::ucfirst($self) }

1;
