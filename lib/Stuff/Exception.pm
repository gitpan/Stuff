package Stuff::Exception;

use Stuff qw/ Exporter /;
use Scalar::Util qw/ blessed /;
use Stuff::Base::Exception;
use Stuff::Base::Error;

our @EXPORT_OK = qw/ error rethrow try catch /;

my $exception_class = 'Stuff::Base::Exception';
my $error_class = 'Stuff::Base::Error';

sub error {
  $error_class->throw( @_ );
}

sub rethrow(;$) {
  my $e = @_ ? $_[0] : $@;
  
  die $e
    if blessed( $e ) && $e->isa( $exception_class );
  
  $error_class->throw( $e );
}

our %expected;

sub try(&) {
  my $code = shift;
  
  local $@;
  local $SIG{__DIE__} = \&rethrow;
  
  eval { &$code(); };
  
  return $@;
}

sub catch(&$) {
  my( $code, $e ) = @_;
  
  local %expected = map { $_ => 1 } map { ref $_ ? @$_ : $_ } $e;
  local $SIG{__DIE__} = \&rethrow;
  
  eval { &$code(); };
  
  if( $@ ) {
    return $@ if $expected{ ref $@ };
  }
  
  return;
}

sub croak {
  for( $_[0] ) {
    die $_ if $_ =~ /\n/;
    
    my( $file, $line ) = ( caller( 1 + $_[1] ) )[1,2];
    die "$_ at $file line $line.\n";
  }
}

1;
