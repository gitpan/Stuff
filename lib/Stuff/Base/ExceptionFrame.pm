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

=head1 NAME

Stuff::Base::ExceptionFrame - Class for exception frame.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut

