#
# File: OP/IPv4Addr.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::IPv4Addr;

use strict;
use warnings;

use OP::Class qw| true false |;
use Perl6::Subs;

use Data::Validate::IP;

use base qw| OP::Str |;

use constant AssertFailureMessage
  => "Received value is not an IPv4 address";

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    sub {
       Data::Validate::IP::is_ipv4("$_[0]")
         || throw OP::AssertFailed(AssertFailureMessage);
    }, @rules
  );

  $parsed{columnType} ||= 'VARCHAR(15)';

  return $class->__assertClass()->new(%parsed);
};

method new(OP::Class $class: Str $string) {
  Data::Validate::IP::is_ipv4($string)
    || throw OP::AssertFailed(AssertFailureMessage);

  my $self = $class->SUPER::new($string);

  return bless $self, $class;
};

true;

__END__

=pod

=head1 NAME

OP::IPv4Addr - Overloaded IPv4 address object class

=head1 VERSION

  $Id: //depotit/tools/source/snitchd-0.20/lib/OP/IPv4Addr.pm#3 $

=head1 SYNOPSIS

  use OP::IPv4Addr;

  my $addr = OP::IPv4Addr->new("127.0.0.1");

=head1 DESCRIPTION

Extends L<OP::Str>. Uses L<Data::Validate::IP> to verify input.

=head1 PUBLIC CLASS METHODS

=over 4

=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::IPv4Addr instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    someAddr  => OP::IPv4Addr->assert(optional()),

    # ...
  };

=item * C<new(OP::Class $class: Str $addr)>

Returns a new OP::IPv4Addr instance which encapsulates the received value.

  my $object = OP::IPv4Addr->new($addr);

=back

=head1 SEE ALSO

L<OP::Str>, L<Data::Validate::IP>

This file is part of L<OP>.

=cut
