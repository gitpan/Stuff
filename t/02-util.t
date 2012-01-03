#!/usr/bin/env perl

use Test::More tests => 4;
use Stuff::Features;

BEGIN {
  use_ok 'Stuff::Util';
  
  my @subs = qw/ plainize clone load_module /;
  Stuff::Util->import( @subs );
  
  for( @subs ) {
    no strict 'refs';
    ok defined *{$_}{CODE}, "$_ imported";
  }
}
