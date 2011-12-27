package Stuff::Features;

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
  
  # use open qw/:utf8 :std/;
  ${^OPEN} = ":utf8\0:utf8";
  
  # use fetures qw/sat switch/;
  feature->import( qw/say switch/ ) if HAS_FEATURE;
}

1;

=head1 NAME

Stuff::Features

=head1 SYNOPSIS

  use Stuff::Features;

is a short replacement for

  use strict;
  use warnings( FATAL => qw/
    closure deprecated glob
    closed layer pipe
    pack portable severe
    digit printf prototype reserved semicolon
    taint threads unpack
  / );
  use utf8;
  use open qw/:utf8 :std/;
  use fetures qw/sat switch/;

=head1 SEE ALSO

L<Stuff>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
