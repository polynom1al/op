#
# File: OP/Domain.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#

package OP::Domain;

use strict;
use warnings;

use OP::Class qw| true false |;
use Perl6::Subs;

use Data::Validate::Domain;

use base qw| OP::Str |;

use constant AssertFailureMessage
  => "Received value is not a domain name";

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    sub {
       Data::Validate::Domain::is_domain("$_[0]")
         || throw OP::AssertFailed(AssertFailureMessage);
    }, @rules
  );

  $parsed{columnType} ||= 'VARCHAR(256)';

  return $class->__assertClass()->new(%parsed);
};

method new(OP::Class $class: Str $string) {
  Data::Validate::Domain::is_domain("$string")
    || throw OP::AssertFailed(AssertFailureMessage);

  my $self = $class->SUPER::new($string);

  return bless $self, $class;
};

true;

__END__

=pod

=head1 NAME

OP::Domain

=head1 VERSION

  $Id: //depotit/tools/source/snitchd-0.20/lib/OP/Domain.pm#3 $

=head1 SYNOPSIS

  use OP::Domain;

  #
  # A fully qualified domain name
  #
  my $domain = OP::Domain->new("example.com");

=head1 DESCRIPTION

Domain name object.

Extends L<OP::Str>. Uses L<Data::Validate::Domain> to verify input.

=head1 PUBLIC CLASS METHODS

=over 4

=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::Domain instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    someAddr  => OP::Domain->assert(optional()),

    # ...
  };

=item * C<new(OP::Class $class: Str $addr)>

Returns a new OP::Domain instance which encapsulates the received value.

  my $object = OP::Domain->new($addr);

=back

=head1 SEE ALSO

L<OP::Str>, L<Data::Validate::Domain>

This file is part of L<OP>.

=cut
