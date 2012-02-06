#!/usr/bin/env perl

use Test::More tests => 10;

BEGIN {
  use_ok 'Stuff::Exceptions';
  Stuff::Exceptions->import( qw/ catch expect / );
  
  package TestException;
  use Stuff -Exception;
}

use Stuff;
use Scalar::Util qw/ blessed /;

is( TestException->new( "123" )->message, '123' );
is( TestException->new( message => "123" )->message, '123' );

eval { TestException->throw( "123" ) };
ok blessed( $@ ) && $@->isa( 'TestException' ), 'exception isa';
ok blessed( $@ ) && $@->message eq '123', 'exception message';
ok blessed( $@ ) && blessed( $@->frames->[0] ), 'exception frame';

for( catch { die "123" } ) {
  ok blessed( $_ ) && $_->isa( 'Stuff::Error' ), 'Stuff::Error is default';
  ok blessed( $_ ) && $_->message =~ /^123/, 'message ok';
}

for( scalar expect { TestException->throw( "123" ) } 'TestException' ) {
  ok blessed( $_ ) && $_->message eq '123' && ref $_->frames eq 'ARRAY' && @{$_->frames} == 0, 'expect ok';
}

for( scalar expect { die "123" } 'TestException' ) {
  ok blessed( $@ ) && $@->message =~ /^123/ && @{$@->frames} != 0 && !$_, 'expect ok';
}
