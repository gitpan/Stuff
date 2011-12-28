package Stuff::Exception;

use Stuff::Features;
use Stuff::Base ();
use Stuff::Base::Exception;
use Stuff::Base::Error;
use Stuff::Util qw/ plainize /;
use Scalar::Util qw/ blessed /;
use Carp;

# Export.
use Exporter 'import';
our @EXPORT_OK = qw/ expect catch caught rethrow /;
our %EXPORT_TAGS = { all => \@EXPORT_OK };

# List of expected exception classes.
our @expected;

# Exception classes.
my $exception_class = 'Stuff::Base::Exception';
my $error_class     = 'Stuff::Base::Error';

sub rethrow(;$) {
  my $e = @_ ? $_[0] : $@;
  
  die $e
    if blessed( $e ) && $e->isa( $exception_class );
  
  $error_class->throw( $e );
}

sub catch(&;$) {
  my $code = shift;
  
  eval {
    local $SIG{__DIE__} = \&rethrow;
    &$code();
  };
  
  if( $@ ) {
    return $@ unless defined $_[0];
    if( blessed $@ ) {
      for( plainize $_[0] ) {
        return $@ if $@->isa( $_ );
      }
    }
    die $@;
  }
  
  return;
}

sub caught {
  my $e = @_ > 1 ? $_[1] : $@;
  blessed( $e ) && $e->isa( $_[0] );
}

sub is_expected {
  my $e = $_[0];
  return unless blessed $e;
  for( @expected ) {
    return 1 if $e->isa( $_ );
  }
  return;
}

sub expect(&;$) {
  my $code = shift;
  
  local @expected = defined $_[0] ? plainize $_[0] : ();
  
  eval {
    local $SIG{__DIE__} = \&rethrow;
    &$code();
  };
  
  return $@ if $@ && is_expected $@;
  return;
}

1;

=head1 NAME

Stuff::Exception - Exception handling stuff

=head1 FUNCTIONS

=head2 C<catch>

=head2 C<caught>

=head2 C<expect>

=head2 C<rethrow>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
