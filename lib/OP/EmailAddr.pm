#
# File: OP/EmailAddr.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::EmailAddr;

use strict;
use warnings;

use OP::Class qw| true false |;
use Perl6::Subs;

use Data::Validate::Email;
use Email::Address;

use base qw| Email::Address OP::Array |;

use constant AssertFailureMessage
  => "Received value is not an email address";

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    sub {
      my $self = shift;

      if ( !ref($self) || !UNIVERSAL::isa($self,"Email::Address") ) {
        $self = $class->new($self);
      }

      Data::Validate::Email::is_email($self->address)
       || throw OP::AssertFailed(AssertFailureMessage);
    }, @rules
  );

  $parsed{columnType} ||= 'VARCHAR(256)';

  return $class->__assertClass()->new(%parsed);
};

method new(OP::Class $class: *@components) {
  my $self = ( @components > 1 )
    ? Email::Address->new(@components)
    : ( Email::Address->parse($components[0]) )[0];

  throw OP::AssertFailed(AssertFailureMessage) if !$self;

  Data::Validate::Email::is_email($self->address())
    || throw OP::AssertFailed(AssertFailureMessage);

  return bless $self, $class;
};

method isa(OP::Class $class: Str $what) {
  return false if $what eq 'OP::Array';

  return UNIVERSAL::isa($class, $what);
};

true;

__END__

=pod

=head1 NAME

OP::EmailAddr - Overloaded RFC 2822 email address object

=head1 VERSION

  $Id: //depotit/tools/source/snitchd-0.20/lib/OP/EmailAddr.pm#4 $

=head1 SYNOPSIS

  use OP::EmailAddr;

  #
  # From address:
  #
  do {
    my $addr = OP::EmailAddr->new('root@example.com');
  }

  #
  # From name and address:
  #
  do {
    my $addr = OP::EmailAddr->new("Rewt", 'root@example.com');
  }

  #
  # From a formatted string:
  #
  do {
    my $addr = OP::EmailAddr->new("Rewt <root@example.com>');
  }

=head1 DESCRIPTION

Extends L<Email::Address>, L<OP::Array>. Uses L<Data::Validate::Email>
to verify input.

=head1 PUBLIC CLASS METHODS

=over 4

=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::EmailAddr instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    someAddr  => OP::EmailAddr->assert(optional()),

    # ...
  };

=item * C<new(OP::Class $class: Str $addr)>

Returns a new OP::EmailAddr instance which encapsulates the received value.

  my $object = OP::EmailAddr->new('root@example.com');

=back

=head1 SEE ALSO

See L<Email::Address> for RFC-related methods inherited by this class.

L<OP::Array>, L<Data::Validate::Email>

This file is part of L<OP>.

=cut
