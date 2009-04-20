#
# File: OP/Any.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Any;

##
## Pragma
##

use strict;
use warnings;
use overload '""' => sub { shift->toYaml() };
use base qw| OP::Scalar |;

##
## Import Libraries
##

use OP::Enum::Bool;
use Perl6::Subs;

##
## Public Class Methods
##

#
#
#
method assert (OP::Class $class: *@rules ) {
  my %parsed = OP::Type::__parseTypeArgs( sub { 1 }, @rules );

  $parsed{columnType} ||= 'TEXT';
  $parsed{optional} = 1;

  return $class->__assertClass()->new( %parsed );
};

#
#
#
method new (OP::Class $class: Any $self) {
  if ( ref( $self ) ) {
    return bless $self, $class;
  } else {
    return bless \$self, $class;
  }
};

##
## End of package
##

true;

__END__

=pod

=head1 NAME

OP::Any - Object class wrapper for any type of variable


=head1 VERSION

  $Id: $

=head1 SYNOPSIS

  use OP::Any;


=head1 DESCRIPTION

Extends L<OP::Scalar>


=head1 METHODS

=head2 Public Class Methods

=over 4


=item * C<assert(OP::Class $class: *@rules)>

Returns a new OP::Type::Any instance which encapsulates the received
L<OP::Subtype> rules.

  create "OP::Example" => {
    #
    # A *very* casual instance var ...
    #
    someVar  => OP::Any->assert(optional()),

    # ...
  };


=item * C<new(OP::Class $class: Any $self)>

Returns a new OP::Any instance which encapsulates the received value.

  my $object = OP::Any->new($stuff);


=head1 DIAGNOSTICS

See L<OP::Class>


=head1 CONFIGURATION AND ENVIRONMENT

See L<OP::Class>


=head1 DEPENDENCIES

See L<OP::Class>


=head1 INCOMPATIBILITIES

See L<OP::Class>


=head1 BUGS AND LIMITATIONS

OP::Any instances may not be C<undef>.

See L<OP::Class>


=head1 SEE ALSO

This file is part of L<OP>.

=cut
