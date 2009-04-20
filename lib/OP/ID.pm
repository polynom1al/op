#
# File: OP/ID.pm
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

OP::ID - Overloaded GUID object class

=head1 DESCRIPTION

Extends L<OP::Scalar> and L<Data::GUID>

ID objects stringify as base64, which makes them as small as practical.

=head1 SYNOPSIS

  use OP::ID;

  #
  # Generate a new GUID
  #
  do {
    my $id = OP::ID->new();

    # ...
  }

  #
  # Instantiate an existing GUID from base64
  #
  do {
    my $id = OP::ID->new("EO2JXisF3hGSSg+s3t/Aww==");

    # ...
  }

You may also instantiate from and translate between string, hex, or
binary GUID forms using the constructors inherited from L<Data::GUID>.

See L<Data::GUID> and L<Data::UUID> for more details.

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::ID;

use strict;
use warnings;

use OP::Enum::Bool;

use Perl6::Subs;
use URI::Escape;

use overload fallback => true,
  '""' => sub { shift->as_base64() };

use base qw| Data::GUID OP::Scalar |;

method new(OP::Class $class: Str ?$self) {
  return $self
    ? Data::GUID::from_base64($class, $self)
    : Data::GUID::new($class);
}

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isStr, @rules
  );

  $parsed{columnType}  ||= 'CHAR(24)';
  $parsed{optional} = true;
            # why? because this won't be set yet inside of new objects.
            # if id is a PRIMARY KEY, it can't be null in the DB, so
            # this works out fine.

  return $class->__assertClass()->new(%parsed);
}

method escaped() {
  return uri_escape($self->as_base64);
}

true;
