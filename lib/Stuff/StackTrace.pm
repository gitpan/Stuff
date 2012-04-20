package Stuff::StackTrace;

use Stuff::Features;
use Stuff::Base -Object;
use Stuff::StackTraceFrame;

# Overload boolean check and stringifiction.
use overload
  bool => sub { 1 },
  '""' => 'to_string',
  fallback => 1;

# Raw frames, as they come from caller().
has raw_frames => sub {
  shift->_collect_frames;
};

# Class for exception frame object.
has frame_class => 'Stuff::StackTraceFrame';

# Processed frames.
has frames => sub {
  my $self = shift;
  
  my @frames;
  my $class = $self->frame_class;
  
  for( @{$self->raw_frames} ) {
    # TODO: filter frames
    push @frames, $class->new( [ @$_ ] );
  }
  
  return \@frames;
};

# Constructor.
sub new {
  my $self = shift->SUPER::new( @_ );
  
  # Collect raw_frames.
  $self->raw_frames;
  
  $self;
}

sub substract {
  my( $self, $other ) = @_;
  
  my $frames1 = $self->raw_frames;
  my $frames2 = ( $other || $self->new )->raw_frames;
  
  if( $frames1 && $frames2 ) {
    for my $f2( reverse @$frames2 ) {
      my $f1 = $frames1->[-1] or last;
      
      $f1->[1] eq $f2->[1] && $f1->[2] eq $f2->[2] or last;
      
      pop @$frames1;
    }
  }
  
  delete $self->{frames};
  
  $self;
}

sub to_string {
  my $self = shift;
  
  join( '' => map {
    "  [".( join( ':' => $_->filename, $_->line ) )."]\n"
  } @{$self->frames} );
}

sub _collect_frames {
  my @frames;
  for( my $i = 2; ; $i++ ) {
    my @c = caller( $i ) or last;
    next if $c[0]->isa( __PACKAGE__ );
    push @frames, \@c;
  }
  return \@frames;
}

1;

__END__
=head1 NAME

Stuff::StackTrace

=head1 METHODS

=head2 C<new>

  my $trace = Stuff::StackTrace->new;
  my $trace = Stuff::StackTrace->new( frame_classs => 'MyStackTraceFrame' );
  my $trace = Stuff::StackTrace->new( raw_frames => \@raw_frames );
  my $trace = Stuff::StackTrace->new( frames => \@frames );
  
=head2 C<to_string>

  my $string = $trace->to_string;
  my $string = "$trace";

=head2 C<substract>

  $trace->substract; # same as $trace->substract( $trace->new );
  $trace->substract( $other_trace );

=head1 ATTRIBUTES

=head2 C<raw_frames>

Stack frames, as they come from caller(...).

=head2 C<frames>

Stack frames converted to objects of class C<frame_class>.

=head2 C<frame_class>

Class for frame objects.

=cut
