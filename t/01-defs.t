#!/usr/bin/env perl

use Test::More tests => 12;
use Stuff::Features;

BEGIN {
  use_ok 'Stuff::Defs';
  
  my @subs = qw/def inherit_defs/;
  Stuff::Defs->import( @subs );
  
  for( @subs ) {
    no strict 'refs';
    ok defined *{$_}{CODE}, "$_ imported";
  }
}

def( 'TestPackage1', def => \&Stuff::Defs::def );
can_ok( 'TestPackage1', 'def' );

TestPackage1::def( arguments => sub ($) { $_[1] } );

is( prototype \&TestPackage1::arguments, '$' );
is( TestPackage1::arguments( 'hello' ), 'hello' );
is( TestPackage1->arguments( 'hello' ), 'hello' );

inherit_defs( 'TestPackage1', 'TestPackage2' );

can_ok( 'TestPackage2', 'def' );
can_ok( 'TestPackage2', 'arguments' );

is( prototype \&TestPackage2::arguments, '$' );
is( TestPackage2::arguments( 'hello' ), 'hello' );
is( TestPackage2->arguments( 'hello' ), 'hello' );
