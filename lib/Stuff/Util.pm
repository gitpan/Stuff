package Stuff::Util;

use Stuff::Features;
use Carp;
use Scalar::Util qw/ blessed reftype refaddr /;
use Exporter 'import';

our @EXPORT_OK = qw/ plainize load_module clone /;

sub plainize {
  map { ref $_ eq 'ARRAY' ? map { plainize( $_ ) } @$_ : $_; } @_;
}

sub load_module($;$) {
  my( $package, $dh ) = @_;
  
  my $module = $package;
  $module =~ s/::|\'/\//g;
  $module .= '.pm';
  
  eval {
    local $SIG{__DIE__} = $dh if $dh;
    
    croak( qq/Empty package name/ )
      unless length $package;
    
    croak( qq/Bad package name "$package"/ )
      unless $package =~ /^([a-z_][a-z_0-9]*::)*[a-z_][a-z_0-9]*$/i;
    
    require $module;
  };
  
  if( $@ ) {
    die $@
      if index( $@, "Can't locate $module " ) != 0;
    
    return;
  }
  
  return 1;
}

sub clone {
}

1;

=head1 NAME

Stuff::Util

=head1 SYNOPSIS

  use Stuff::Util ':all';
  
  load_module( 'Some::Module' );  
  plainize( [ 10, [ 0, 2, 4, [ 5, 6, 7 ] ] ] ); # => ( 10, 0, 2, 4, 5, 6, 7 )

=head1 FUNCTIONS

=head2 C<load_module>

  load_module( $module [, $exception_converter] );

Loads module by its name (e.g. 'Some::Module').
If module can't be found, returns empty list or undef.
If module loads normally or been loaded before, returns 1.
If any error happen duering loading, this error will be thrown.

  load_module( 'ExistentModule' ); # => 1
  load_module( 'NonExistentModule' ); # => undef
  load_module( 'ModuleWithError' ); # dies

Second optional argument defines "error handler" or "exception converter".
The only purpose for it is conversion of standart perl error into your custom error object.
Like this:

  use Scalar::Util 'blessed';
  
  load_module( $module, sub {
    $@->rethrow if blessed $@;
    $exception_class->throw( $@ );
  } );

=head2 C<plainize>

  plainize( @list );

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
