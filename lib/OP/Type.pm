#
# File: OP/Type.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package OP::Type;

=pod

=head1 NAME

B<OP::Type> - Type definitions for L<OP::Object> subclass instances

=head1 DESCRIPTION

A Type describes the parameters which an L<OP::Object> instance
variable and/or database table column must conform to, and does so in
a detailed and compact form. The OP::Type class also provides methods
for strict runtime testing and enforcement of asserted values.

If a caller tries to do something contrary to a Type, OP will
throw an exception, which causes an exit unless caught using C<eval>/C<$@>
or C<try>/C<catch> (see L<Error>).

=head2 Dynamic Subclasses

The "built-in" subclasses derived from OP::Type and L<OP::Subtype>
are auto-generated, and have no physical modules.

Each concrete object class in OP provides access to its respective Type
subclass, via the C<__assertClass()> and C<__assert()> class methods. For
example, L<OP::Str> provides access to the dynamic class OP::Type::Str;
L<OP::Hash> does so for OP::Type::Hash; etc.

Types may be modified by Subtypes (e.g. C<::optional()>). See
L<OP::Subtype> for more details and a list of these rule
types. Subtype subclasses are allocated from the definitions found
in the %OP::Type::RULES package variable.

=head1 SYNOPSIS

=head2 Using "package"

When using C<package>, instance variables are asserted using C<member()>.

  package OP::Example;

  use OP;

  use base qw| OP::Node |;

  #
  # Instance variable "foo" will contain optional string data:
  #
  member foo => OP::Str->assert( ::optional() );

  ...

  true;

=head2 Using "create"

If creating classes using C<create()>, instance variables are asserted
in the prototype as inline keys.

  use OP;

  create "OP::Example" => {
    #
    # Instance variable "foo" will contain optional string data:
    #
    foo => OP::Str->assert( ::optional() ),

    ...
  };

More examples can be found in the L<OP::Class> and L<OP::Subtype>
modules, and in the documentation for specific object classes.

The remainder of this doc contains information which is generally
only useful if hacking on core OP internals.

=head1 TEST SUBS

These subs are defined as package constants, and are used internally by
OP. These subs are not for general usage, but for coding OP internals.

Each returns a CODE block which may be used to validate data types.

When executed, the test subs throw an C<OP::AssertFailed> exception on
validation failure, and return C<true> on success.

=over 4

=item * insist(Any $value, Code $test);

Runs the received value against a test sub.

  #
  # OP will agree, $str is string-like.
  #
  my $str = "Hello";

  insist($str, OP::Type::isStr);

  #
  # This will throw an exception:
  #
  my $notStr = { };

  insist($notStr, OP::Type::isStr);

=item * isStr(Str $value)

Returns a CODE ref which tests the received value for string-ness.

=item * isFloat(Num $value)

Returns a CODE ref which tests the received value for float-ness.

=item * isInt(Num $value)

Returns a CODE ref which tests the received value for int-ness.

=item * isArray(Array $value)

Returns a CODE ref which tests the received value for array-ness.

=item * isBool(Bool $value)

Returns a CODE ref which tests the received value for bool-ness.

=item * isCode(Code $code)

Returns a CODE ref which tests the received value for CODE-ness.

=item * isHash(Hash $value)

Returns a CODE ref which tests the received value for hash-ness.

=item * isIO(IO $io)

Returns a CODE ref which tests the received value for IO-ness.

=item * isRef(Ref $ref)

Returns a CODE ref which tests the received value for ref-ness.

=item * isRule(Rule $rule)

Returns a CODE ref which tests the received value for regex-ness.

=item * isScalar(Str $scalar)

Returns a CODE ref which tests the received value for scalar-ness.

=head1 FUNCTIONS

OP::Type's exported functions are used to bootstrap OP::Class
subclasses.

=over 4

=item * C<member($key,$type)>

Instance variable assertion function.

C<member()> is only needed when using C<package>. If using C<create()>,
assertions are just inline keys in the prototype, and this function should
not be used directly.

The C<member()> function defines allowed instance variables for any
objects of a class, and is exported by the OP::Class module for this
purpose. Assertions restrict the attributes and values which objects
of a class may have. The attributes asserted in a class translate to
same-named database table columns.

If no class members are asserted, objects will receive "free-form"
getters and setters. These "schema-less" instances may be saved to disk,
but not to a database.

  package OP::Example;

  use OP;

  use base "OP::Node";

  our @__someClassVar = true;

  member someInstanceVar => OP::Str->assert();

  member anotherInstanceVar => OP::Str->assert();

  method publicInstanceMethod() {
    # Code here, $self will be set for you.
  }

  method _privateInstanceMethod() {
    # Code here, $self will be set for you.
  }

  method publicClassMethod(OP::Class $class:) {
    # Code here, $class will be set for you.
  }

  method __privateClassMethod(OP::Class $class:) {
    # Code here, $class will be set for you.
  }

  true;

=back

=cut

use strict;
use warnings;

use Perl6::Subs;

use Error qw| :try |;

use OP::Enum::Bool;
use OP::Exceptions;
use OP::Redefines;
use OP::Persistence::MySQL; # For RefOpts constants

use base qw| Exporter OP::Class::Dumper OP::Class |;

our @EXPORT;

sub insist(Any $value, Code $code) { &$code($value) }

sub member(Str $key, OP::Type $type) {
  return false unless defined($key);

  my $caller = caller();

  my $asserts = $caller->asserts();

  $asserts->{$key} = $type;

  return true;
}

use constant isStr => sub(Str $value) {
  my ($package, $filename, $line) = caller(1);

  throw OP::AssertFailed("undef is not a string, check $package:$line")
    if !defined $value;

  throw OP::AssertFailed("Received value is not a string, check $package:$line")
    if ref($value) && !overload::Overloaded($value);

  return true;
};

use constant isFloat => sub(Num $value) {
  throw OP::AssertFailed("undef is not a number")
    if !defined $value;

  throw OP::AssertFailed("Received value is not a float")
    if ( $value !~ /^\d+$/ ) && ( $value !~ /^\d+\.\d+$/ );

  return true;
};

use constant isInt => sub(Num $value) {
  if ( !defined($value)
    || (
      !UNIVERSAL::isa($value, "OP::Int")
      && $value !~ /^\d+$/
    )
  ) {
    throw OP::AssertFailed("Received value is not an integer");
  }

  return true;
};

use constant isArray => sub(Array $value) {
  if ( ref($value) && UNIVERSAL::isa($value, 'ARRAY') ) {
    return true;
  }

  throw OP::AssertFailed("Received value is not an Array");
};

use constant isBool => sub(Bool $value) {
  if ( !defined($value) || scalar(@_)
    || $value !~ /^\d+$/
    || ( $value != 0 && $value != 1 )
  ) {
    throw OP::AssertFailed("Received value must be 0 or 1");
  }

  return true;
};

use constant isCode => sub(Code $code) {
  if ( !defined($code) ) {
    throw OP::AssertFailed("Code ref must not be undef");
  }

  return true;
};

use constant isHash => sub(Hash $value) {
  if ( ref($value) && UNIVERSAL::isa($value, 'HASH') ) {
    return true;
  }

  throw OP::AssertFailed("Received value is not a Hash");
};

use constant isIO => sub(IO $io) {
  if ( !defined($io) ) {
    throw OP::AssertFailed("IO ref must not be undef");
  }

  return true;
};

use constant isRef => sub(Ref $ref) {
  if ( !defined($ref) ) {
    throw OP::AssertFailed("Ref must not be undef");
  }

  return true;
};

use constant isRule => sub(Rule $rule) {
  if ( !defined($rule) ) {
    throw OP::AssertFailed("Rule must not be undef");
  }

  return true;
};

use constant isScalar => sub(Str $scalar) {
  if ( !defined($scalar) ) {
    throw OP::AssertFailed("Scalar must not be undef");
  }

  return true;
};

=pod

=head1 PUBLIC CLASS METHODS

These methods are used internally by OP at a low level, and normally
won't be accessed directly.

If creating a new Type subclass from scratch, its constructors
and methods would need to implement this interface.

=over 4

=item * $class->new(%args)

Instantiate a new OP::Type object.

Consumed args are as follows:

  my $type = OP::Type::MyType->new(
    code       => ..., # CODE ref to test with
    allowed    => ..., # ARRAY ref of allowed vals
    default    => ..., # Literal default value
    columnType => ..., # Override column type string
    sqlValue   => ..., # Override SQL insert value
    unique     => ..., # true|false
    optional   => ..., # true|false
    serial     => ..., # true|false
    min        => ..., # min numeric value
    max        => ..., # max numeric value
    size       => ..., # fixed length or scalar size
    minSize    => ..., # min length or scalar size
    maxSize    => ..., # max length or scalar size
    regex      => ..., # optional regex which value must match
    memberType => ..., # Sub-assertion for arrays
    memberClass  => ..., # Name of inline or external class
    uom        => ..., # String label for human reference
    descript   => ..., # Human-readable description
    example    => ..., # An example value for human reference
    onDelete   => ..., # MySQL foreign constraint reference option
    onUpdate   => ..., # MySQL foreign constraint reference option
    
  );

=back

=cut

method new(OP::Type $class: *%args) {
  my $self = { };

  for my $key ( keys %args ) {
    $self->{"__$key"} = $args{$key};
  }

  return bless $self, $class;
}


=pod

=head1 READ-ONLY ATTRIBUTES

Although these are public-ish, there normally should not be a need
to access them directly.

=over 4

=item * $type->allowed()

Returns the array of allowed values for this asserted attribute.

XXX TODO This would be much faster as a hash table keyed on value

=cut

method allowed(Str ?$key) {
  return if !$self->{__allowed} || !ref $self->{__allowed};

  if ( ref($self->{__allowed}) eq 'CODE' ) {
    #
    # Allowed values are derived from a function at runtime:
    #
    my $answer = &{ $self->{__allowed} }( $self, $key );

    return @{ $answer };
  } else {
    #
    # Allowed values are specified in a hard coded list:
    #
    return @{ $self->{__allowed} };
  }
}


=pod

=item * $type->code()

Returns the CODE ref used to test this attribute's value for
correctness. The code ref is a sub{ } block which takes the
value as an argument, and returns a true or false value.

=cut

method code() {
  insist( $self->{__code}, isCode );

  return $self->{__code};
}


=pod

=item * $type->memberType()

Used for Arrays only. Returns a "sub-assertion" (another OP::Type
object) which is unrolled for array elements.

=cut

method memberType() {
  return $self->{__memberType};
}


=pod

=item * $type->memberClass()

Used for L<OP::ExtID> assertions only. Returns the name of the
class which this attribute is a pointer to.

=cut

method memberClass() {
  return $self->{__memberClass};
}


=pod

=item * $type->externalClass()

Convenience wrapper for C<memberClass>, but also works for Arrays of
ExtIDs. One-to-one foreign keys are asserted as ExtID, but one-to-many
keys are an ExtID assertion wrapped in an Array assertion. This means
a lot of double-checking in code later, so this method exists to handle
both cases without fuss.

Used for L<OP::ExtID> assertions (one-to-one) and L<OP::Array> assertions
encapsulating an ExtID, to return the name of the class which the current
attribute is a pointer to.

=cut

method externalClass() {
  my $extClass;

  if ( $self->isa("OP::Type::ExtID") ) {
    $extClass = $self->memberClass()
  } elsif (
    $self->isa("OP::Type::Array")
      && $self->memberType()->isa("OP::Type::ExtID")
  ) {
    $extClass = $self->memberType()->memberClass();
  }

  return $extClass;
}


=pod

=item * $type->objectClass()

Returns the concrete object class which this type is for.

=cut

method objectClass() {
  #
  # Allow usage as class or instance method:
  #
  return $self->class()
    ? $self->class()->get("objectClass")
    : $self->get("objectClass");
};

=pod

=back

=head1 PUBLIC INSTANCE METHODS

=over 4

=item * $self->class()

Object wrapper for Perl's built-in ref() function

=cut

method class() {
  return ref($self);
}


=pod

=item * $type->test($key, $value)

Send the received value to the code reference returned by
$type->code(). Warns and returns a false value on test failure,
otherwise returns true.

C<$key> is included so the caller may know what the warning was for!

XXX TODO The individual tests need moved out of this monolithic sub,
and into the assertion code tests. Will make things cleaner and faster.

=cut

method test(Str $key, Any $value) {
  #
  # Reject undefined values
  #
  if ( !defined $value ) {
    if ( $self->optional() ) {
      return true;
    } else {
      my ( $package, $filename, $line ) = caller;

      throw OP::AssertFailed(
        "undef is not permitted for $key"
      );
    }
  }

  #
  # Compare against allowed values, if any:
  #
  my @allowed = $self->allowed($value);

  if ( @allowed && !grep { $_ eq $value } @allowed ) {
    throw OP::AssertFailed(
      "Value \"$value\" is not permitted for $key"
    );
  }

  my $default = $self->default();

  my $defaultRef = ref($default);
  my $valueRef = ref($value);

  #
  # Compare size against fixed or min/max sizes
  #
  if (
    defined $self->size()
    || defined $self->minSize()
    || defined $self->maxSize()
  ) {
    my $haveSize;
    my $wantSize = $self->size(); # For fixed size asserts

    my $minSize = $self->minSize();
    my $maxSize = $self->maxSize();

    #
    # Determine what the "size" of the object in the current context is
    #
    if ( !$valueRef || UNIVERSAL::isa($value, "OP::Scalar") ) {
      #
      # Scalar length
      #
      $haveSize = length($value);
    } elsif ( UNIVERSAL::isa($value, 'ARRAY') ) {
      #
      # Array size
      #
      $haveSize = scalar(@{ $value });
    } elsif ( UNIVERSAL::isa($value, 'HASH') ) {
      #
      # Key count
      #
      $haveSize = scalar(keys %{ $value });
    } else {
      #
      # Unknown
      #
      throw OP::RuntimeError(
        "UNSUPPORTED (FIXME?): Can't tell size of a $valueRef for $key"
      );
    }

    if ( defined $wantSize ) {
      #
      # Fixed size was specified
      #
      if ( $wantSize != $haveSize ) {
        throw OP::AssertFailed(
          sprintf 'Received size for %s was %i, needs to be %i',
            $key, $haveSize, $wantSize
        );
      }
      
    } else {
      #
      # Min and/or max sizes were specified
      #
      if ( defined $minSize && $haveSize < $minSize ) {
        throw OP::AssertFailed(
          sprintf 'Received size for %s was %i, needs to be >= %i',
            $key, $haveSize, $minSize
        );
      }

      if ( defined $maxSize && $haveSize > $maxSize ) {
        throw OP::AssertFailed(
          sprintf 'Received size for %s was %i, needs to be <= %i',
            $key, $haveSize, $maxSize
        );
      }
    }
  }

  #
  # Compare value against min and max values (not size, as above)
  #
  if ( defined $self->min() || defined $self->max() ) {
    my $min = $self->min();
    my $max = $self->max();

    if ( defined $min && "$value" < $min ) {
      throw OP::AssertFailed(
        sprintf 'Received value of %s was %f, needs to be >= %f',
          $key, $value, $min
      );
    }

    if ( defined $max && "$value" > $max ) {
      throw OP::AssertFailed(
        sprintf 'Received value for %s was %f, needs to be <= %f',
          $key, $value, $max
      );
    }
  }

  #
  # Compare value against a required regex match
  #
  if ( defined($value) && defined($self->regex()) ) {
    my $regex = $self->regex();

    if ( $value !~ /$regex/ ) {
      throw OP::AssertFailed(
        sprintf 'Received value for %s was %s, needs to match /%s/',
          $key, $value, $regex
      );
    }
  }

  #
  # Test value using the sub returned by $self->code()
  #
  my $sub = $self->code();

  if ( !$sub ) {
    throw OP::RuntimeError(
      "BUG IN CALLER: No code block set in assertion for key $key"
    );
  }

  try {
    insist $value, $sub;
  } catch Error with {
    my $error = $_[0];

    throw OP::AssertFailed(
      sprintf 'Assertion for %s "%s" failed: %s',
        $key, $value, $error
    );
  };

  #
  # Test individual array elements
  #
  if (
    ref($value) && $self->memberType()
      && $self->memberType()->objectClass()->isa("OP::Array")
  ) {
    for my $element ( @{ $value } ) {
      my $memberSuccess = $self->memberType->test($key, $element);

      if ( !$memberSuccess ) {
        throw OP::AssertFailed(
          "Element assertion for key $key failed"
        );
      }
    }
  }

  return true;
}

#
# Each key becomes a Subtype subclass.
#
# The subs test the received Subtype argument (if needed),
# and return a sanitized value.
#
# eg. uom($argument)
#
# See the test() instance method, which performs test actions based on
# assertion rules (you'll need to modify test() to handle new cases)
#
our %RULES = (
  max => sub(Num $value) {
    insist( $value, isFloat ) && return $value;
  },

  columnType => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  default => sub(*@value) {
    if ( scalar(@value) == 0 ) {
      return undef;
    } elsif ( scalar(@value) == 1 ) {
      return $value[0];
    } else {
      return \@value;
    }
  },

  descript => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  example => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  min => sub(Num $value) {
    insist( $value, isFloat ) && return $value;
  },

  maxSize => sub(Int $value) {
    insist( $value, isInt ) && return $value;
  },

  minSize => sub(Int $value) {
    insist( $value, isInt ) && return $value;
  },

  # CASCADE, SET NULL, etc
  onDelete => sub(Str $value) {
    insist( $value, isStr )
      && ( grep { uc($value) eq $_ } @{ ( OP::Persistence::MySQL::RefOpts ) } )
      || ( throw OP::InvalidArgument("Invalid reference option specified") );

    return uc($value);
  },

  onUpdate => sub(Str $value) {
    insist( $value, isStr )
      && ( grep { uc($value) eq $_ } @{ ( OP::Persistence::MySQL::RefOpts ) } )
      || ( throw OP::InvalidArgument("Invalid reference option specified") );

    return uc($value);
  },

  optional => sub() {
    throw OP::InvalidArgument(
      "Extra arguments received by optional()"
    ) if @_ > 1;

    return true;
  },

  regex => sub(Rule $regex) {
    return $regex;
  },

  serial => sub() {
    throw OP::InvalidArgument(
      "Extra arguments received by serial()"
    ) if @_ > 1;

    return true;
  },

  size => sub(Int $value) {
    insist( $value, isInt ) && return $value;
  },

  sqlValue => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  sqlInsertValue => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  sqlUpdateValue => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },

  unique => sub(Any ?$value) {
    #
    # Kind of a hack, but this allows any of:
    #
    #   ::unique(true)   # Key on self
    #
    # or
    #
    #   ::unique("key1") # Key on self + key1
    #   ::unique("key1","key2") # Key on self+key1+key2
    #
    # etc., for as many attributes which make up the
    # combinatory key, up to whatever the InnoDB byte
    # limit for keys is (768ish)
    #
    if ( $value && !ref($value)
      && !Scalar::Util::looks_like_number($value)
    ) {
      $value = [ $value ];
    }

    if ( $value && UNIVERSAL::isa($value, 'ARRAY') ) {
      #
      # Keying on multiple items:
      #
      for my $key ( @{ $value } ) {
        insist( $key, isStr );
      }
    } else {
      $value = $value ? true : false;
    }

    return $value;
  },

  uom => sub(Str $value) {
    insist( $value, isStr ) && return $value;
  },
);

#
# Dynamically create Subtype subclasses, and accessors in Type
# which are overloaded as constructor shortcuts for rules.
#
for ( keys %RULES ) {
  my $ruleClass = "OP::Subtype::$_";

  eval qq|
    #
    # Package name tells us which type of Subtype is in play:
    #
    package $ruleClass;

    use base "OP::Subtype";

    package OP::Type;

    sub $_ {
      #
      # If called as method, act as read-only Type accessor.
      #
      # If called as function, delegate to Subtype constructor.
      #
      if ( 
        ref(\$_[0]) && UNIVERSAL::isa(\$_[0], "OP::Type")
      ) {
        return \$_[0]->{__$_}
      } else {
        return $ruleClass\->new(\@_);
      }
    }
  |;
}

@EXPORT = ( qw| true false member insist |, keys %RULES );

#
# Helper function so Str, Int, and Float don't have
# to repeat this bit of code:
#
sub __parseTypeArgs(Code $testSub, *@args) {
  my %parsed;

  my @allowedValues;

  if ( scalar @args ) {
    for my $value ( @args ) {
      my $ref = ref($value) || "";
      $ref =~ s/.*:://;

      if ( $ref && $RULES{$ref} ) {
        #
        # Matches a rule; return result of the rule's value test
        #
        $parsed{$ref} = &{ $RULES{$ref} }( $value->value() );
      } elsif ( !$ref || UNIVERSAL::isa($ref,'OP::Subtype::default') ) {
        #
        # Is a default or literal value, test against received testSub.
        #
        # Add all literal values to the class's list of allowed values.
        #
        insist $value, $testSub;

        push( @allowedValues, $value ) if !$ref;
      }
    }
  }

  #
  # "Allowed values" can be an array defined at compile time, or a sub{ }
  # which returns an array at runtime.
  #
  # Check to see if we have an array or a coderef:
  #
  $parsed{allowed} = @allowedValues == 1
    && ref($allowedValues[0])
    && UNIVERSAL::isa($allowedValues[0], "CODE")
    ? $allowedValues[0]
    : \@allowedValues;

  $parsed{code} = $testSub;

  return %parsed;
}

=pod

=back

=head1 SEE ALSO

L<OP::Class>, L<OP::Subtype>

This file is part of L<OP>.

=head1 REVISION

$Id: $

=cut

true;
