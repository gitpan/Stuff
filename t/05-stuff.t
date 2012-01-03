#!/usr/bin/env perl

use Test::More tests => 17;

BEGIN {
  use_ok 'Stuff';
  Stuff->import;
}

BEGIN {
  package TestDef::Base;
  use Stuff -def;
  
  $INC{'TestDef/Base.pm'} = __FILE__;
  
  def APPLE => 'McIntosh';
  def PEAR => 'Pyrus communis';
  
  def table => sub () {
    my $pkg = $_[0];
    $pkg =~ s/.*::([^:]+)(?:::)?$/$1/;
    return lc $pkg;
  };
  
  def set_table => sub($) {
    Stuff::Subs::make $_[0], table => $_[1];
  };
}

BEGIN {
  package TestDef::Child1;
  use Stuff qw/ TestDef::Base /;
  
  def PEAR => 'Pyrus nivalis';
  def APPLE => 'Granny Smith';
  
  set_table 'something';
}

BEGIN {
  package TestDef::Child2;
  use Stuff qw/ TestDef::Base /;
}

BEGIN {
  package TestDef::Child3;
  use Stuff qw/ TestDef::Child1 /;
}

# isa.
isa_ok 'TestDef::Child1', 'TestDef::Base';
isa_ok 'TestDef::Child2', 'TestDef::Base';
isa_ok 'TestDef::Child3', 'TestDef::Base';
isa_ok 'TestDef::Child3', 'TestDef::Child1';

# defs.
is TestDef::Base::APPLE,     'McIntosh'      , 'TestDef::Base::APPLE';
is TestDef::Child1::APPLE,   'Granny Smith'  , 'TestDef::Child1::APPLE';
is TestDef::Child2::APPLE,   'McIntosh'      , 'TestDef::Child2::APPLE';
is TestDef::Child3::APPLE,   'Granny Smith'  , 'TestDef::Child3::APPLE';

is TestDef::Base::PEAR,      'Pyrus communis', 'TestDef::Base::PEAR';
is TestDef::Child1::PEAR,    'Pyrus nivalis' , 'TestDef::Child1::PEAR';
is TestDef::Child2::PEAR,    'Pyrus communis', 'TestDef::Child2::PEAR';
is TestDef::Child3::PEAR,    'Pyrus nivalis' , 'TestDef::Child3::PEAR';

is TestDef::Base::table,     'base'          , 'TestDef::Base::table';
is TestDef::Child1::table,   'something'     , 'TestDef::Child1::table';
is TestDef::Child2::table,   'child2'        , 'TestDef::Child2::table';
is TestDef::Child3::table,   'something'     , 'TestDef::Child3::table';

