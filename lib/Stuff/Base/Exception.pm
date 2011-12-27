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

# Verbosity level of "to_string".
has verbose => 1;

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
  my $self = shift->SUPER::new( @_ == 1 ? ( message => $_[0] ) : @_ );
  
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

Stuff::Base::Exception - Exception class.

=head1 SYNOPSIS

  # Create own exception class.
  package HttpAbortException;
  use Stuff -Exception; # <= push @ISA, qw( Stuff::Base::Exception );
  has status => 0;
  has no_frames => 1;
  
  # Instantiate exception.
  my $e = HttpAbortException->new( status => 404, message => 'Request aborted' );
  
  # 
  say $e->status; # => 404
  
  # Automatic stringification.
  say $e; # => 'Request aborted'
  
  # Throw exception.
  $e->throw;
  
  # Or instantiate and throw.
  HttpAbortException->throw( status => 404 );
  
  eval {
    HttpAbortException->throw( status => 404 );
  };
  
  $@->status; # => 404

=head1 METHODS

C<Stuff::Base::Exception> inherit all methods from Stuff::Base::Object and implements the following:

=head2 new

  $package->new;
  $package->new( $message );
  $package->new( %args );

=head2 throw

  $package->throw;
  $package->throw( $message );
  $package->throw( %args );
  $object->throw;

=head2 to_string

  $object->to_string;

Returns a string that representing exception. Usually this is value of message translated to string.

=head1 ATTRIBUTES

=head2 message

A message associated with exception. In general cases it should not be only string or number, any reference is acceptable.

=head2 no_frames

If it has true value then no stack frames will be collected duering object instantiation. Default value if false. 

=head2 raw_frames

=head2 frames

=head2 frame_class

=head1 SEE ALSO

L<Stuff>, L<Stuff::Exception>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut

