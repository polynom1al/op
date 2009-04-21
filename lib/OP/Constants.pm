#
# File: OP/Constants.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Constants;

=pod

=head1 NAME

OP::Constants - Loads .oprc values as Perl constants

=head1 DESCRIPTION

Loads C<.oprc> values as Perl constants, with optional export.

C<.oprc> is a YAML file containing constant values used by OP. It should
be located under C<$ENV{OP_HOME}>, which defaults to C</opt/op>.

An example C<.oprc> is included in the top level directory of this
distribution, and also given later in this document.

=head1 SECURITY

The <.oprc> file represents the keys to the kingdom.

Treat your <.oprc> file with the same degree of lockdown as you would
with system-level executables and their associated configuration
files. It should not be kept in a location where untrusted parties
can write to it, or where any unaudited changes can occur.

=head1 SYNOPSIS

To import constants directly, just specify them when using OP::Constants:

 use OP::Constants qw| dbUser dbPass |;

 my $dbUser = dbUser;
 my $dbPass = dbPass;

To access the constants without importing them into the caller's
namespace, just fully qualify them:

 use OP::Constants;

 my $dbUser = OP::Constants::dbUser;
 my $dbPass = OP::Constants::dbPass;

=head1 EXAMPLE

The following is an example of an .oprc file. The file contents must be
valid YAML:

  ---
  ldapHost: ldap
  yamlRoot: /opt/op/yaml
  sqliteRoot: /opt/op/sqlite
  scratchRoot: /tmp
  dbName: op
  dbHost: localhost
  dbPass: ~
  dbPort: 3306
  dbUser: op
  memcachedHosts:
    - 127.0.0.1:31337
  rcsBindir: /usr/bin
  rcsDir: RCS
  syslogHost: ~

=cut

use strict;

use IO::File;
use YAML::Syck;
use Sys::Hostname;

use Error qw| :try |;

use OP::Exceptions;

require Exporter;

use base qw( Exporter );

our @EXPORT_OK;

#
# Default RC file location if OP_HOME is not set
#
use constant DefaultPath => '/opt/op';

sub init {
  my $RC = shift;
  my $caller = caller;

  $ENV{OP_HOME} ||= DefaultPath;

  #
  # Private package variables
  #
  my $rc;

  my $path = join('/',$ENV{OP_HOME},$RC);

  my $override = join('/',$ENV{OP_HOME},hostname(),$RC);

  if ( $ENV{OP_HOME} && -f $path ) {
    my $file = IO::File->new($path, 'r')
      || throw OP::FileAccessError("Could not read $path: $@");

    my @yaml;

    while ( <$file> ) { push @yaml, $_ }

    $file->close();

    eval {
      $rc = YAML::Syck::Load( join('', @yaml) ) || die $@;
    };

    throw OP::RuntimeError($@) if $@;

    throw OP::RuntimeError("Unexpected format in $path: Should be a HASH")
      if !ref($rc) || ref($rc) ne 'HASH';

    if ( -f $override ) {
      my $file = IO::File->new($override, 'r')
        || throw OP::FileAccessError("Could not read $override: $@");

      my @overrideYAML;

      while ( <$file> ) { push @overrideYAML, $_ }

      $file->close();

      my $overlay;

      eval {
        $overlay = YAML::Syck::Load( join('', @overrideYAML) ) || die $@;
      };

      throw OP::RuntimeError($@) if $@;

      throw OP::RuntimeError("Unexpected format in $override: Should be a HASH")
        if !ref($overlay) || ref($overlay) ne 'HASH';

      for my $key ( keys %{ $overlay } ) {
        $rc->{$key} = $overlay->{$key};
      }
    }
  } else {
    print STDERR q(!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    _  _____ _____ _____ _   _ _____ ___ ___  _   _ 
   / \|_   _|_   _| ____| \ | |_   _|_ _/ _ \| \ | |
  / _ \ | |   | | |  _| |  \| | | |  | | | | |  \| |
 / ___ \| |   | | | |___| |\  | | |  | | |_| | |\  |
/_/   \_\_|   |_| |_____|_| \_| |_| |___\___/|_| \_|
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
);

    my $current = $ENV{OP_HOME} || "";
                                                    
    print STDERR "\n";
    print STDERR "\"$0\" needs some help finding a file.\n";
    print STDERR "\n";
    print STDERR "HERE'S WHAT'S WRONG:\n";
    print STDERR "  OP can't find a valid constants file, \".oprc\"!\n";
    print STDERR "  .oprc lives under OP_HOME (currently: \"$current\").\n";
    print STDERR "\n";
    print STDERR "HOW TO FIX THIS:\n";
    print STDERR "  Set OP_HOME to the location of a valid .oprc, in the\n";
    print STDERR "  shell environment or calling script. For example:\n";
    print STDERR "\n";
    print STDERR "  In bash:\n";
    print STDERR "    export OP_HOME=\"/path/to\"\n";
    print STDERR "\n";
    print STDERR "  Or in $0:\n";
    print STDERR "    \$ENV{OP_HOME} = \"/path/to\";\n";
    print STDERR "\n";
    print STDERR "This must be corrected before proceeding.\n";
    print STDERR "\n";
    print STDERR "A starter .oprc should have accompanied this\n";
    print STDERR "distribution. An example is also given on the\n";
    print STDERR "OP::Constants manual page.\n";
    print STDERR "\n";

    exit(2);
  }

  do {
    no strict "refs";

    @{"$caller\::EXPORT_OK"} = ( );
  };

  for my $key ( keys %{$rc} ) {
    do {
      no strict "refs";
      no warnings "once";

      push @{"$caller\::EXPORT_OK"}, $key;
    };

    eval qq|
      package $caller;

      use constant \$key => \$rc->{$key};
    |;

    throw OP::RuntimeError($@) if $@;
  }
}

init '.oprc';

=pod

=head1 CUSTOM RC FILES

Developers may create self-standing rc files for application-specific
consumption. Just use OP::Constants as a base, and invoke C<init> for the
named rc file.

Just as C<.oprc>, the custom rc file must contain valid YAML, and it lives
under C<$ENV{OP_HOME}>.

For example, in a hypothetical C<.myapprc>:

  ---
  hello: howdy

Hypothetical package MyApp/Constants.pm makes any keys available
as Perl constants:

  package MyApp::Constants;

  use base qw| OP::Constants |;

  OP::Constants::init(".myapprc");

  1;

Callers may consume the constants package, requesting symbols for export:

  use MyApp::Constants qw| hello |;

  say hello;

  #
  # Prints "howdy"
  #

=head1 DIAGNOSTICS

=over 4

=item * No .oprc found

C<.oprc> needs to exist in order for OP to compile and run.  In the
event that an <.oprc> was not found, OP will exit with an instructive
message. Read and follow the provided steps when this occurs.

=item * Some symbol not exported

  Uncaught exception from user code:
        "______" is not exported by the OP::Constants module
  Can't continue after import errors ...

This is a compile error. A module asked for a non-existent constant
at compile time.

The most likely cause is that OP found an C<.oprc>, but the required
symbol wasn't in the file. To fix this, add the missing named
constant to your C<.oprc>. This typically happens when the C<.oprc>
which was loaded is for an older version of OP than is actually
installed.

This error may also be thrown when the C<.oprc> is malformed.
If the named constant is present in the file, but this error is still
occurring, check for broken syntax within the file. Missing ":"
seperators between key and value pairs, or improper levels of
indenting are likely culprits.

=back

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Constants.pm#8 $

=head1 SEE ALSO

L<YAML::Syck>, L<constant>

This file is part of L<OP>.

=cut

1;
