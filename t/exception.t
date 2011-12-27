#!/usr/bin/env perl

use Test::More tests => 9;

BEGIN {
  use_ok 'Stuff::Exception';
  Stuff::Exception->import( qw/ try catch error / );
  
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

for( try { die "123" } ) {
  ok blessed( $_ ) && $_->isa( 'Stuff::Base::Error' ), 'Stuff::Base::Error is default';
  ok blessed( $_ ) && $_->message =~ /^123/, 'exception message ok';
}

for( catch { TestException->throw( "123" ) } 'TestException' ) {
  ok blessed( $_ ) && $_->message eq '123' && ref $_->frames eq 'ARRAY' && @{$_->frames} == 0, 'catch expected class';
}

for( catch { die "123" } 'TestException' ) {
  ok blessed( $@ ) && $@->message =~ /^123/ && @{$@->frames} != 0 && !$_, 'catch ok';
}
