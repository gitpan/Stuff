#!/usr/bin/env perl

use 5.006;
use ExtUtils::MakeMaker;

my %args = (
  NAME => 'Stuff',
  VERSION_FROM => 'lib/Stuff.pm',
  AUTHOR => 'Nikita Zubkov <nikzubkov@gmail.com>',
  PREREQ_PM => {
    'Test::More' => 0
  },
  test => { TESTS => 't/*.t' }
);

my $mmver = $ExtUtils::MakeMaker::VERSION;

$args{LICENSE}= 'artistic_2' if $mmver >= 6.3002;

WriteMakefile( %args );
