#
# File: OP/Name.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Name;

use strict;
use warnings;

use Perl6::Subs;

use base qw| OP::Str |;

method assert(OP::Class $class: *@rules) {
  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isStr, @rules
  );

  if ( !$parsed{columnType} ) {
    $parsed{columnType} = 'VARCHAR(128)';
    $parsed{maxSize}    = 128;
  }

  #
  # Name must always be unique, one way or another...
  #
  if ( !$parsed{unique} ) {
    $parsed{unique} = 1;
  }

  return $class->__assertClass()->new(%parsed);
}

1;
__END__
=pod

=head1 NAME

OP::Name

=head1 SYNOPSIS

  create "My::Class" => {
    name => OP::Name->assert( ::optional )

    # ...
  };

=head1 SEE ALSO

This file is part of L<OP>.

=cut
