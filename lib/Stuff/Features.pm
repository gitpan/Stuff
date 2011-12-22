package Stuff::Features;

use strict; no warnings;

use constant {
  HAS_UTF8 => eval { require utf8; },
  HAS_FEATURE => eval { require feature; }
};

binmode( $_, ':utf8' )
  for qw/STDIN STDOUT STDERR/;

sub import {
  strict->import;
  
  warnings->unimport;
  warnings->import( FATAL => qw/
    closure deprecated glob
    closed layer pipe
    pack portable severe
    digit printf prototype reserved semicolon
    taint threads unpack
  / );
  
  ${^OPEN} = ":utf8\0:utf8";
  
  utf8->import if HAS_UTF8;
  feature->import( sprintf ":%vd", $^V ) if HAS_FEATURE;
}

1;
