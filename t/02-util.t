#!/usr/bin/env perl

use Test::More tests => 3;
use Stuff::Features;

BEGIN {
  use_ok 'Stuff::Util';
  
  my @subs = qw/ is_package_name load_module /;
  Stuff::Util->import( @subs );
  
  for( @subs ) {
    no strict 'refs';
    ok defined *{$_}{CODE}, "$_ imported";
  }
}
