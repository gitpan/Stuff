package Stuff::Base::Exception;

use Stuff -Object;
use Stuff::Base::ExceptionFrame;
use Scalar::Util 'blessed';

# Overload boolean check and stringifiction.
use overload
  bool => sub { 1 },
  '""' => 'to_string',
  fallback => 1;

# Message associated with exception.
has -message;

# Collect exception frames?
#  * false - collect
#  * true - don't collect
has no_frames => 0;

# Raw frames, as they come from caller().
has raw_frames => sub {
  my $self = shift;
  ( $self->no_frames || $self->is_expected ) ? [] : $self->_collect_frames;
};

# Class for exception frame object.
has frame_class => 'Stuff::Base::ExceptionFrame';

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
  my $self = shift->SUPER::new( ( @_ == 1 && !ref $_[0] ) ? ( message => $_[0] ) : @_ );
  
  # Collect raw_frames.
  $self->raw_frames;
  
  $self;
}

# Exception stringificator.
sub to_string {
  ''.$_[0]->{message}
}

# Check whatever this exception is expected and we can skip frames collection.
sub is_expected {
  $Stuff::Exception::expected{ ref $_[0] };
}

# Throw exception.
sub throw {
  my $self = shift;
  die $self if blessed $self;
  die $self->new( @_ );
}

# Rethrow exception.
sub rethrow {
  my $self = shift;
  
  if( @_ ) {
    my $e = $_[0];
    die $e if blessed( $e ) && $e->isa( __PACKAGE__ );
  }
  else {
    die $self if blessed $self;
  }
  
  die $self->new( @_ );
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

Stuff::Base::Exception - Exception class

=head1 SYNOPSIS
  
  # Exception instantiation.
  $exception_class->new( 'oops!' );
  $exception_class->new( message => 'oops!', no_frames => 1 );
  $exception_class->new( { messaeg => 'oops!', raw_frames => [ ... ] } );
  
  # Throw exception.
  $exception_class->throw( 'oops!' );
  $exception_class->throw( message => 'oops!', no_frames => 1 );
  $exception_class->throw( { messaeg => 'oops!', raw_frames => [ ... ] } );
  
  # Custom exception.
  package MyException;
  use Stuff -Exception;
  has no_frames => 1; # do not collect frames

=head1 METHODS

C<Stuff::Base::Exception> inherit all methods from Stuff::Base::Object and implements the following:

=head2 new

=head2 throw

=head2 rethrow

=head2 to_string

=head1 ATTRIBUTES

=head2 message

=head2 no_frames

=head2 raw_frames

=head2 frames

=head2 frame_class

=cut
