#
# File: OP/Node.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Node;

=head1 NAME

OP::Node

=head1 DESCRIPTION

Extends L<OP::Hash> and L<OP::Persistence> to form an abstract base
storable object class.

Subclasses should override the class callback methods inherited from
L<OP::Persistence> to customize backing store options.

=head1 INHERITANCE

This class inherits additional class and object methods from the
following packages:

L<OP::Class> > L<OP::Object> > L<OP::Hash> > OP::Node

L<OP::Persistence> > OP::Node

=cut

use strict;
use warnings;

#
# include() isn't invoked on "use base", so this is needed here too:
#
use OP::Hash;

use Perl6::Subs;

use base qw| OP::Persistence OP::Hash |;

method assert(OP::Class $class: *@rules) {
  my $test = sub(OP::Class $value) {
    if ( ref($value) && UNIVERSAL::isa($value, $class) ) {
      return true;
    }

    throw OP::AssertFailed("Received value is not a $class");
  };

  my %parsed = OP::Type::__parseTypeArgs($test, @rules);

  $parsed{columnType} ||= 'TEXT';

  return $class->__assertClass()->new(%parsed);
};

method new(OP::Class $class: *@args) {
  my $self = $class->SUPER::new(@args);

  return $self;
}

method save(*@args) {
  $self->SUPER::save(@args);
}

=pod

=head1 SEE ALSO

This file is part of L<OP>.

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Node.pm#5 $

=cut

true;
