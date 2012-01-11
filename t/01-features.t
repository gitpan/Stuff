#!/usr/bin/env perl

use Test::More tests => 10;

BEGIN {
  use_ok 'Stuff::Features';
  Stuff::Features->import;
}

BEGIN {
  package TestFeaturesImport;
  $INC{"TestFeaturesImport.pm"} = __FILE__;
  sub import {
    Stuff::Features->import
  }
}

use constant HAS_FEATURE => eval { require feature };

sub check_strict {
  my( $name, $init, $code ) = @_;
  
  ok( do {
    local $SIG{__WARN__} = sub {};
    
        eval qq{ $init; no strict '$name'; $code; }
    && !eval qq{ no strict '$name'; $init; $code; }
  }, qq/strict "$name"/ );
}

# strict.
check_strict 'subs', 'use Stuff::Features', 'my $var = Hello';
check_strict 'vars', 'use Stuff::Features', '$var = 1';
check_strict 'refs', 'use Stuff::Features', '*{"__"} = {}';

check_strict 'subs', 'use TestFeaturesImport', 'my $var = Hello';
check_strict 'vars', 'use TestFeaturesImport', '$var = 1';
check_strict 'refs', 'use TestFeaturesImport', '*{"__"} = {}';

# TODO: warnings.

# feature.
ok( !HAS_FEATURE || eval( 'my $a; given(1) { when(1) { $a = 1 } }; $a' ), 'feature' );

{
  package _A;                     sub m { 'A' }
  package _B; our @ISA = qw/ _A /;
  package _C; our @ISA = qw/ _A /;    sub m { 'C' }
  package _D; our @ISA = qw/ _B _C /; use Stuff::Features; 
}

is( _D->m, 'C' );

# utf8.
my $str = "я";
ok utf8::is_utf8( $str ), 'utf8';
