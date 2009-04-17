#
# File: OP/Num.pm
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

OP::Num

=head1 DESCRIPTION

Scalar-backed overloaded object class for numbers.

Extends L<OP::Scalar> and L<Scalar::Number>.

=head1 SYNOPSIS

  use OP::Num;

  my $num = OP::Num->new(12345);

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::Num;

use strict;
use warnings;

use Perl6::Subs;
use Scalar::Number;
use OP::Enum::Bool;

use base qw| Scalar::Number OP::Scalar |;


# + - * / % ** << >> x
# <=> cmp
# & | ^ ~
# atan2 cos sin exp log sqrt int

our %overload = (
  '++'  => sub { ++$ {$_[0]} ; shift }, # from overload.pm
  '--'  => sub { --$ {$_[0]} ; shift },
  '+'   => sub { "$_[0]" + "$_[1]" },
  '-'   => sub { "$_[0]" - "$_[1]" },
  '*'   => sub { "$_[0]" * "$_[1]" },
  '/'   => sub { "$_[0]" / "$_[1]" },
  '%'   => sub { "$_[0]" % "$_[1]" },
  '**'  => sub { "$_[0]" ** "$_[1]" },
);

use overload fallback => true, %overload;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isFloat, @rules
  );

  $parsed{maxSize} ||= 11;
  $parsed{columnType} ||= 'INT(11)';

  return $class->__assertClass()->new(%parsed);
}

method abs() { CORE::abs(${ $self }) }

method atan2(Num $num) { CORE::atan2(${ $self }, $num) }

method cos() { CORE::cos(${ $self }) }

method exp() { CORE::exp(${ $self }) }

method int() { CORE::int(${ $self }) }

method log() { CORE::log(${ $self }) }

method rand() { CORE::rand(${ $self }) }

method sin() { CORE::sin(${ $self }) }

method sqrt() { CORE::sqrt(${ $self }) }

1;
