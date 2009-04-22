use strict;
use diagnostics;

use Test::More tests => 30;

my $temprc = "/tmp/.oprc";

#
# OP will not compile without a valid .oprc.
#
# Set up a fake .oprc so testing may proceed.
#
# This gets removed when testing is complete.
#
open(OPRC, ">", $temprc) || die $@;

print OPRC q|
---
yamlRoot: /tmp/yaml
sqliteRoot: /tmp/sqlite
scratchRoot: /tmp
dbName: op
dbHost: localhost
dbPass: ~
dbPort: 3306
dbUser: op
rcsBindir: /usr/bin
rcsDir: RCS
memcachedHosts: ~
syslogHost: ~
|;
close(OPRC);

$ENV{OP_HOME} = '/tmp';

#
# Very basic OP tests.
#
# Does not test database stuff yet - Only very high-level
# functionality, such as constructors, are covered.
#

###
### Class prototyping tests
###

use_ok("OP");

my $testClass = "OP::TestClass";

is( createTestClass($testClass), $testClass );

isa_ok( createTestObject($testClass), $testClass );

is( testSetter($testClass), 1 );

is( testGetter($testClass), "Bar" );

is( testDeleter($testClass), undef );

###
### Object Constructor tests
###

#
# SCALARS
#
isa_ok( OP::Any->new("Anything"), "OP::Any" );

isa_ok( OP::Bool->new(1), "OP::Bool" );
isa_ok( OP::Bool->new(0), "OP::Bool" );

isa_ok( OP::Code->new( sub { } ), "OP::Code" );

isa_ok( OP::Domain->new( "example.com" ), "OP::Domain" );

isa_ok( OP::Double->new( 22/7 ), "OP::Double" );

my $id = OP::ID->new;
isa_ok( $id, "OP::ID");
isa_ok( OP::ExtID->new($id), "OP::ExtID");

isa_ok( OP::Float->new( 22/7 ), "OP::Float" );

isa_ok( OP::Int->new(10), "OP::Int");

isa_ok( OP::IPv4Addr->new("127.0.0.1"), "OP::IPv4Addr" );

isa_ok( OP::Name->new("Nom"), "OP::Name" );

isa_ok( OP::Num->new(42), "OP::Num");

my $foo = "Hello";
isa_ok( OP::Ref->new(\$foo), "OP::Ref");

isa_ok( OP::Rule->new(qr/example/), "OP::Rule");

isa_ok( OP::Scalar->new(42), "OP::Scalar");

isa_ok( OP::Str->new("String Theory"), "OP::Str");

isa_ok( OP::TimeSpan->new(42), "OP::TimeSpan");

isa_ok( OP::URI->new("http://www.example.com/"), "OP::URI");

#
# ARRAYS
#
isa_ok( OP::Array->new("123", "456", "abc", "def"), "OP::Array");

isa_ok( OP::DateTime->new(time), "OP::DateTime" );

isa_ok( OP::EmailAddr->new('root@example.com'), "OP::EmailAddr");

#
# HASHES
#
isa_ok( OP::Hash->new, "OP::Hash");

isa_ok( OP::Recur->new, "OP::Recur");

#
# Remove the tempfile
#
unlink $temprc;

sub createTestClass {
  my $class = shift;

  return create( $class => {
    __BASE__ => "OP::Hash"
  } );
};

sub createTestObject {
  my $class = shift;

  return $class->new;
};

sub testSetter {
  my $class = shift;

  my $self = $class->new;

  return $self->setFoo("Bar");
};

sub testGetter {
  my $class = shift;

  my $self = $class->new;

  $self->setFoo("Bar");

  return $self->foo;
};

sub testDeleter {
  my $class = shift;

  my $self = $class->new;

  $self->setFoo("Bar");

  $self->deleteFoo("Bar");

  return $self->foo;
};
