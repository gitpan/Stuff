package Stuff::Exception;

use Stuff 'Exporter';
use Scalar::Util qw/ blessed /;
use Stuff::Base::Exception;
use Stuff::Base::Error;

our %expected;
our @EXPORT_OK = qw/ error rethrow try catch /;

# 
my $exception_class = 'Stuff::Base::Exception';
my $error_class     = 'Stuff::Base::Error';

sub error($@) {
  $error_class->throw( @_ );
}

sub rethrow(;$) {
  my $e = @_ ? $_[0] : $@;
  
  die $e
    if blessed( $e ) && $e->isa( $exception_class );
  
  $error_class->throw( $e );
}

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

1;

=head1 NAME

Stuff::Exception - Exception handling stuff

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut

