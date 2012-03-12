#!/usr/bin/env perl

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Stuff',
  VERSION_FROM => 'lib/Stuff.pm',
  AUTHOR => 'Nikita Zubkov <nikzubkov@gmail.com>',
  ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? (
    LICENSE => 'artistic_2'
  ) : () ),
  PREREQ_PM => {
    'Carp' => 0,
    'Scalar::Util' => 0,
    'Test::More' => 0,
  },
  test => { TESTS => 't/*.t' }
);
