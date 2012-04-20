package Stuff::Exception;

use Stuff::Features;
use Stuff::Base -StackTrace;
use Scalar::Util 'blessed';

# Overload boolean check and stringifiction.
use overload
  bool => sub { 1 },
  '""' => 'to_string',
  fallback => 1;

# Message associated with exception.
has message => 'Exception!';

# Verbosity level of "to_string".
has verbose => 0;

# Collect exception frames?
#  * false - collect
#  * true - don't collect
has no_frames => 0;

# Raw frames, as they come from caller().
has raw_frames => sub {
  my $self = shift;
  ( $self->no_frames || $self->is_expected ) ? [] : $self->_collect_frames;
};

# Constructor.
sub new {
  shift->SUPER::new( @_ == 1 ? ( message => $_[0] ) : @_ );
}

# Exception stringificator.
sub to_string {
  my $self = shift;
  my $message = ''.$self->message;
  $message .= "\n" . SUPER::to_string( @_ ) if $self->verbose;
  $message;
}

# Check whatever this exception is expected and we can skip frames collection.
sub is_expected {
  my $self = shift;
  for( @Stuff::Exceptions::expected ) {
    return 1 if $self->isa( $_ );
  }
  return;
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

1;

__END__
=head1 NAME

Stuff::Exception - Exception with context

=head1 SYNOPSIS

  # Create own exception class.
  package HttpAbortException;
  use Stuff -Exception; # <= push @ISA, qw( Stuff::Exception );
  has status => 0;
  has no_stack_trace => 1;
  
  # Instantiate exception.
  my $e = HttpAbortException->new( status => 404, message => 'Request aborted' );
  
  # Get attibute.
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

C<Stuff::Exception> inherit all methods from C<Stuff::StackTrace> and implements the following:

=head2 C<new>

  $package->new;
  $package->new( $message );
  $package->new( %args );

=head2 C<throw>

  $package->throw;
  $package->throw( $message );
  $package->throw( %args );
  $object->throw;

=head2 C<to_string>

  $object->to_string;
  "$object";

Returns a string that represents exception. By default it is a message translated to string.

=head1 ATTRIBUTES

=head2 C<message>

Optional message associated with exception. In general cases it can be any object, not string or number only.

=head2 C<no_frames>

If it has true value then no stack frames will be collected duering object instantiation. Default value is false. 

=head1 SEE ALSO

L<Stuff>, L<Stuff::Exception>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
