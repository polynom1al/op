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

OP::Constants

=head1 DESCRIPTION

Loads C<.oprc> values as Perl constants, with optional export.

C<.oprc> is a YAML file containing constant values used by OP. It should
be located under C<$ENV{OP_HOME}>, which defaults to C</opt/op>.

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
valid YAML.

  ---
  dbHost: localhost
  dbPass: ~
  dbPort: 3306
  dbUser: op
  memcachedHosts:
    - 127.0.0.1:31337
  sqliteRoot: /opt/op/sqlite
  yamlRoot: /opt/op/yaml
  scratchRoot: /tmp
  apiUser: root

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
use constant RC => '.oprc';

$ENV{OP_HOME} ||= DefaultPath;

#
# Default exported values if RC file is not usable
#
use constant DefaultYamlRoot => '/tmp/yaml';
use constant DefaultSqliteRoot => '/tmp/sqlite';
use constant DefaultScratchRoot => '/tmp/scratch';
use constant DefaultDbName => 'op';
use constant DefaultDbHost => 'localhost';
use constant DefaultDbPass => '~';
use constant DefaultDbPort => '3306';
use constant DefaultDbUser => 'op';
use constant DefaultMemcacheHosts => [ '127.0.0.1:31337' ];
use constant DefaultUrlRoot => 'http://127.0.0.1/';
use constant DefaultRcsBindir => '/usr/bin';
use constant DefaultRcsDir => 'RCS';

#
# Private package variables
#
my $rc;

my $path = join('/',$ENV{OP_HOME},RC);

my $override = join('/',$ENV{OP_HOME},hostname(),RC);

if ( $ENV{OP_HOME} && -f $path ) {
  my $file = IO::File->new($path, 'r')
    || throw OP::FileAccessError("Could not read $path: $@");

  my @yaml;

  while ( <$file> ) { push @yaml, $_ }

  $file->close();

  eval {
    $rc = YAML::Syck::Load( join('', @yaml) );
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
      $overlay = YAML::Syck::Load( join('', @overrideYAML) );
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

  exit(2);

  $rc = {
    yamlRoot => DefaultYamlRoot,
    sqliteRoot => DefaultSqliteRoot,
    scratchRoot => DefaultScratchRoot,
    dbName => DefaultDbName,
    dbHost => DefaultDbHost,
    dbPass => DefaultDbPass,
    dbPort => DefaultDbPort,
    dbUser => DefaultDbUser,
    memcachedHosts => DefaultMemcacheHosts,
    rcsBindir => DefaultRcsBindir,
    rcsDir => DefaultRcsDir,
  };
}

for my $key ( keys %{$rc} ) {
  push @EXPORT_OK, $key;

  eval qq| use constant $key => \$rc->{$key}; |;

  throw OP::RuntimeError($@) if $@;
}

=pod

=head1 REVISION

$Id: //depotit/tools/source/snitchd-0.20/lib/OP/Constants.pm#8 $

=head1 SEE ALSO

L<YAML::Syck>, L<constant>

This file is part of L<OP>.

=cut

1;
