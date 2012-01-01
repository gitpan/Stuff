#!/usr/bin/env perl

use Test::More;

if( eval q/use Test::NoTabs; 1/ ) {
  all_perl_files_ok();
}
else {
  plan skip_all => 'No Test::NoTabs module';
}
