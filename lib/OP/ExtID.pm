#
# File: OP/ExtID.pm
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

OP::ExtID

=head1 DESCRIPTION

Scalar-backed overloaded object class for foreign base64-encoded GUIDs

Extends L<OP::ID>.

=head1 SYNOPSIS

  use OP::ExtID;

  my $id = OP::ExtID->new("EO2JXisF3hGSSg+s3t/Aww==");

=head1 PUBLIC CLASS METHODS

=over 4

=item * $class->assert([$query], @rules)

C<ExtID()> assertions are like pointers defining relationships with
other classes, or within a class to define parent/child hierarchy.

Attributes asserted as C<ExtID()> must match an id in the specified
class's database table.

C<ExtID()> may be wrapped in an C<Array()> assertion for handling
one-to-many relationships, at a small performance cost.

If using MySQL, C<ExtID> also enforces database-level foreign key
constraints. In addition to enforcing allowed values on the database
level, this will incur a CASCADE operation on DELETE and UPDATE events
(meaning if a parent is deleted or updated, the corresponding child
rows will be deleted or updated as well; always use parent id in a child
object, rather than child id in a parent object).

The following example illustrates self-referencing and externally
referencing attributes with ExtID, using the "Folder" and "Document"
desktop paradigm. Each saved object becomes a row in a database table.

Create a folder class for documents and other folders:

  #
  # File: ExampleFolder.pm
  #

  use OP;

  create "OP::ExampleFolder" => {
    #
    # Folders can go in other folders:
    #
    parentId => OP::ExtID->assert(
      "OP::ExampleFolder",
      ::optional()
    ),

    ...
  };

A document class. Documents refer to their parent folder:

  #
  # File: ExampleTextDocument.pm
  #

  use OP;
  use OP::ExampleFolder;

  create "OP::ExampleTextDocument" => {
    #
    # This doc's location in the folder hierarchy
    #
    folderId => OP::ExtID->assert("OP::ExampleFolder"),

    #
    # Textual content of the document
    #
    content  => OP::Str->assert( columnType("TEXT") ),

    # ...
  };

Caller example which populates some test folders and docs:

  #!/bin/env perl
  #
  # File: somecaller.pl
  #

  use strict;
  use warnings;

  use OP::ExampleFolder;
  use OP::ExampleTextDocument;

  sub main {
    #
    # A parent folder named "General"
    #
    my $folder = OP::ExampleFolder->spawn("General");
    $folder->save();

    #
    # A child folder named "Specific"
    #
    my $subfolder = OP::ExampleFolder->spawn("Specific");
    $subfolder->setFolderId( $folder->id() );
    $subfolder->save();

    #
    # Put a test document "README" in the parent folder:
    #
    my $readme = OP::ExampleTextDocument->spawn("README");
    $readme->setFolderId( $folder->id() );
    $readme->setContent("Lorem Ipsum Foo! Bla bla bla...");
    $readme->save();

    #
    # Put a "Test Text Doc" doc in the sub-folder:
    #
    my $doc = OP::ExampleTextDocument->spawn("Test Text Doc");
    $doc->setFolderId( $subfolder->id() );
    $doc->setContent("Lorem Ipsum Foo! Bla bla bla...");
    $doc->save();
  }

  main();

If a string is specified as a second argument to C<ExtID()>, it will be
used as a SQL query, which selects a subset of Ids used as allowed
values at runtime. If this query is not given, a flat, immutable list
of Ids will be plugged in for allowed values at compile time.

  create "OP::Example" => {
    userId => OP::ExtID->assert(
      "OP::Example::User",
      "select id from example_user where foo = 1"
    ),

    # ...
  };

=cut
# 
# XXX TODO ???: Add support for actions other than CASCADE; allow toggling
# of foreign key constraints; permit lazy checking of values at db rather
# than app level, that is: give the option to ignore allowed(), and let
# the DB take care of it entirely. the app would then let you set()
# invalid values, but the DB wouldn't let you save() them, which might be a
# good option for closer-to-realtime performance. The app-level check is
# still a good early indicator for data problems, but it can be a costly
# operation.
#
=pod

=back

=head1 SEE ALSO

This file is part of L<OP>.

=cut

package OP::ExtID;

use strict;
use warnings;

use Perl6::Subs;

use base qw| OP::ID |;

method assert(OP::Class $class: *@rules) {
  my $externalClass = shift @rules;
  my $query = $rules[0];

  my %parsed = OP::Type::__parseTypeArgs(
    OP::Type::isStr, @rules
  );

  $parsed{columnType} ||= 'CHAR(24)';

  if ( $query && !ref $query ) {
    $parsed{allowed} = sub { $externalClass->__selectMulti($query) };
  } else {
    $parsed{allowed} = sub {
      my $assertion = shift;
      my $value = shift;

      my $q = sprintf( q| SELECT %s FROM %s WHERE %s = %s |,
        $assertion->memberClass()->__primaryKey(),
        $assertion->memberClass()->tableName(),
        $assertion->memberClass()->__primaryKey(),
        $assertion->memberClass()->quote($value)
      );

      return $externalClass->__selectMulti($q);
    }
  }

  $parsed{memberClass} = $externalClass;

  return $class->__assertClass()->new(%parsed);
}

1;
