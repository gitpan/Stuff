package Stuff::StackTrace;

use Stuff::Features;
use Stuff::Base -Object;
use Stuff::ExceptionFrame;

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
has frame_class => 'Stuff::ExceptionFrame';

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

sub to_string {
  
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

=head1 NAME

Stuff::StackTrace

=head1 METHODS

=head2 C<grab>

=head1 ATTRIBUTES

=head2 C<raw_frames>

Stack frames, as they come from caller(...).

=head2 C<frames>

Stack frames converted to objects.

=head2 C<frame_class>

=cut
