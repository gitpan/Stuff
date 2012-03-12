package Stuff::StackTraceFrame;

use Stuff::Features;

# Overload boolean check and stringifiction.
use overload
  bool => sub { 1 },
  '""' => 'to_string',
  fallback => 1;

sub new {
  bless $_[1], $_[0]
}

sub to_string {
  my $self = shift;
  join ':' => $self->filename, $self->line;
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

Stuff::StackTraceFrame - Exception frame class

=head1 SYNOPSIS

  my $frame = Stuff::StackTraceFrame->new( [ caller( ... ) ] );

=head1 METHODS

=head2 new

  my $frame = Stuff::StackTraceFrame->new( [ caller( 0 ) ] );

=head2 package

=head2 filename

=head2 line

=head2 subroutine

=head2 has_args

=head2 wantarray

=head2 evaltext

=head2 is_require

=head2 hints

=head2 bitmask

=head2 hinthash

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
