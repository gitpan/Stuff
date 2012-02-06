#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
  use_ok 'Stuff::StackTrace';
  
  package TestException;
  use Stuff -StackTrace;
}

use Stuff;
use Scalar::Util qw/ blessed /;

my $trace = Stuff::StackTrace->new;
ok $trace;
ok blessed( $trace->frames->[0] );
