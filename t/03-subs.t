#!/usr/bin/env perl

use Test::More tests => 10;
use Stuff::Features;

BEGIN {
  use_ok 'Stuff::Subs';
}

Stuff::Subs::make( 'TestPackage1', def => \&Stuff::Subs::make );
can_ok( 'TestPackage1', 'def' );

TestPackage1::def( arguments => sub ($) { $_[1] } );

is( prototype \&TestPackage1::arguments, '$' );
is( TestPackage1::arguments( 'hello' ), 'hello' );
is( TestPackage1->arguments( 'hello' ), 'hello' );

Stuff::Subs::inherit( 'TestPackage2', 'TestPackage1' );

can_ok( 'TestPackage2', 'def' );
can_ok( 'TestPackage2', 'arguments' );

is( prototype \&TestPackage2::arguments, '$' );
is( TestPackage2::arguments( 'hello' ), 'hello' );
is( TestPackage2->arguments( 'hello' ), 'hello' );
