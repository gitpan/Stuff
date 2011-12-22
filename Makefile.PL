#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Stuff',
  VERSION_FROM => 'lib/Stuff.pm',
  AUTHOR => 'Nikita Zubkov <nikzubkov@gmail.com>',
  test => { TESTS => 't/*.t' }
);
