#
# File: OP/Shell.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
use OP;

use Lexical::Persistence;
use Term::ReadLine;

create "OP::Shell" => {
  __BASE__ => "OP::Hash",

  _init => method() {
    my $class = $self->class();

    $self->{_perl} = Lexical::Persistence->new();
    $self->{_buffer} = OP::Array->new();

    $self->{_perl}->do("use OP::Class qw| create true false |;\n");

    return true;
  },

  help => method() {
    print "Commands:\n";
    print "  empty line    # compile & continue\n";
    print "  exit          # exit\n";
    print "  ?pkgname      # perldoc for named package\n";
    print "  !cmd          # spawn system shell and run cmd\n";
    print "\n";
  },

  historyFile => method() {
    #
    # Set up history file
    #
    return $ENV{HOME}
      ? join("/", $ENV{HOME}, ".op_history")
      : ".op_history";
  },

  run => method() {
    print "Welcome to the OP Perl shell.\n";
    print "\n";

    $self->help();

    my $perl = $self->{_perl};
    my $buffer = $self->{_buffer};

    my $prompt = "op> ";

    my $term = Term::ReadLine->new($0);

    #
    # Set up history file
    #
    my $historyFile = $self->historyFile();

    if ( -e $historyFile ) {
      open(HIST,'<', $historyFile);
      while(my $row = <HIST>){
        chomp $row;

	$term->addhistory($row);
      }
      close(HIST);
    }

    my $attribs = $term->Attribs();

    #
    # Set up tab completion
    #
    $attribs->{completion_entry_function} =
      $attribs->{list_completion_function};

    $attribs->{completion_word} = [
      "OP::Class", "OP::Object",
      "OP::Persistence", "OP::Array", "OP::Hash",
      "OP::Example", "OP::Utility",
      "my", "use", "require", "if", "else", "sub", "constant", 
      OP::Class->members(),
      # OP::Class::members("OP::Persistence"),
      # OP::Class::members("OP::Utility"),
      OP::Object->members(),
      OP::Array->members(),
      OP::Hash->members()
    ];

    #
    # Main event loop
    #
    while(1) {
      while( my $line = $term->readline($prompt) ) {
        if ( $line =~ /^\?(\w+.*)/ ) {
          print "Loading $1 documentation, please wait...\n";

          system("perldoc $1");

        } elsif ( $line =~ /^\!(\w+.*)/ ) {
          system($1);

        } elsif ( $line =~ /^(\?|help|h)$/i ) {
          $self->help();

        } elsif ( $line =~ /^exit$/i ) {
          exit();

        } else {
          $buffer->push($line);
        }
      }

      next if $buffer->isEmpty();

      try {
        $perl->do( $buffer->join("\n") );
      } catch Error with {
        my $error = shift;

        print "Compile failed! $error\n";
      };

      if ( -e $historyFile ) {
        $term->append_history($buffer->size(), $historyFile);
      } else {
        $term->WriteHistory($historyFile);
      }

      $buffer->clear();
    }
  },

};
__END__
=pod

=head1 NAME

OP::Shell - Experimental interactive Perl 5 shell

=head1 SYNOPSIS

  use OP::Shell;

  my $shell = OP::Shell->new();

  $shell->run();

A wrapper script, C<opsh>, is included with this distribution.

=head1 BUGS

  Source filtering syntax does not work in interactive mode.

=head1 SEE ALSO

This file is part of L<OP>.

=cut
