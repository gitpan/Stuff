package Stuff::Features;

use 5.008;
use strict;
use utf8;
no warnings;

use constant HAS_FEATURE => eval { require feature; };

# use open qw/:utf8 :std/;
binmode( $_, ':utf8' )
  for qw/STDIN STDOUT STDERR/;

sub import {
  # use strict;
  strict->import;
  
  # no warnings;
  # use warnings( FATAL => ... );
  warnings->unimport;
  warnings->import( FATAL => qw/
    closure deprecated glob
    closed layer pipe
    pack portable severe
    digit printf prototype reserved semicolon
    taint threads unpack
  / );
  
  # use utf8;
  utf8->import;
  
  # use open qw/:utf8/;
  ${^OPEN} = ":utf8\0:utf8";
  
  # use fetures qw/sat switch/;
  feature->import( qw/say switch/ ) if HAS_FEATURE;
}

1;

=head1 NAME

Stuff::Features - Set up code compiling and excecution features

=head1 SYNOPSIS

  use Stuff::Features;

is a short replacement for

  use strict;
  no warnings;
  use warnings( FATAL => qw/
    closure deprecated glob
    closed layer pipe
    pack portable severe
    digit printf prototype reserved semicolon
    taint threads unpack
  / );
  use utf8;
  use open qw/:utf8 :std/;
  use feature qw/say switch/;

=head1 SEE ALSO

L<Stuff>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
