#!/usr/bin/env perl

use Test::More tests => 16;

BEGIN {
  use_ok 'Stuff::Base::Object';
}

BEGIN {
  package TestObject;
  use Stuff -Object;
  has -attr1;
  has [qw/ attr2 attr3 /] => 'attr';
  our $count = 0;
  has -attr4 => sub { $count++; 'attr4' };
}

can_ok 'TestObject', 'new';
can_ok 'TestObject', 'has';

my $obj1 = TestObject->new( attr1 => 10, attr2 => 20 );
my $obj2 = TestObject->new( attr2 => undef );

ok $obj1;
ok $obj2;
ok $obj1->attr1 == 10;
ok $obj1->attr2 == 20;
ok $obj1->attr3 eq 'attr';
ok $obj1->attr4 eq 'attr4';
ok !defined $obj2->attr1;
ok !defined $obj2->attr2;
ok $obj2->attr3 eq 'attr';
ok $obj2->attr4 eq 'attr4';
ok $obj1->attr1( 20 ) eq $obj1;
ok $obj1->attr1 == 20;
ok $TestObject::count == 2;
