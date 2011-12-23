#!/usr/bin/env perl

use Test::More tests => 6;

BEGIN {
  use_ok 'Stuff::Features';
  Stuff::Features->import;
}

use constant HAS_FEATURE => eval { require feature };

sub check_strict {
  my( $name, $code ) = @_;
  
  ok( do {
    local $SIG{__WARN__} = sub {};
    
        eval qq{ use Stuff; no strict '$name'; $code; }
    && !eval qq{ no strict '$name'; use Stuff; $code; }
  }, qq/strict "$name"/ );
}

# strict.
check_strict 'subs', 'my $var = Hello';
check_strict 'vars', '$var = 1';
check_strict 'refs', '*{"__"} = {}';

# TODO: warnings.

# feature.
ok( !HAS_FEATURE || eval( 'my $a; given(1) { when(1) { $a = 1 } }; $a' ), 'feature' );

# utf8.
my $str = "я";
ok utf8::is_utf8( $str ), 'utf8';
