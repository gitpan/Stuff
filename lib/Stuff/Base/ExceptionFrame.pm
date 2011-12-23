package Stuff::Base::ExceptionFrame;

use Stuff;

sub new {
  bless $_[1], $_[0]
}

BEGIN {
  my $i = 0;
  my @methods = qw/
    package
    filename
    line
    subroutine
    has_args
    wantarray
    evaltext
    is_require
    hints
    bitmask
    hinthash
  /;
  
  for( @methods ) {
    eval qq/sub $_ { \$_[0][${\($i++)}] }; 1/ or die $@;
  }
}

1;
