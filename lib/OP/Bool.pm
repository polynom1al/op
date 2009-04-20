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

OP::Bool - Overloaded object class for booleans

=head1 DESCRIPTION

Extends L<OP::Scalar>.

=head1 SYNOPSIS

  use OP::Bool;

  my $bool = OP::Bool->new($condition ? OP::Bool::true : OP::Bool::false);

  if ( $bool ) {
    print "It's true!\n";
  } else {
    print "Clearly false.\n";
  }

These methods are silly, but they exist.

  if ( $bool->isTrue() ) {
    print "That's affirmative\n";
  }

  if ( $bool->isFalse() ) {
    print "Negative on that, Houston\n";
  }

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Bool;

use strict;
use warnings;

use OP::Enum::Bool;
use OP::Num;

use Perl6::Subs;

use base qw| OP::Scalar |;

use overload %OP::Num::overload;

method new(OP::Class $class: Bool $self) {
  OP::Type::insist $self, OP::Type::isBool;
  
  return $class->SUPER::new($self);
}

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isBool, @rules
  );

  $parsed{allowed}  = [ false, true ];
  $parsed{optional} = false;
  $parsed{default}  = false if !defined $parsed{default};
  $parsed{columnType}  ||= 'INTEGER(1)';

  return $class->__assertClass()->new(%parsed);
}

method isTrue() {
  my $class = $self->class();

  return $self
    ? $class->new(true)
    : $class->new(false);
}

method isFalse() {
  my $class = $self->class();

  return $self
    ? $class->new(false)
    : $class->new(true);
}

true;
