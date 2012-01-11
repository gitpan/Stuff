package Stuff::Subs;

use Stuff::Features;
use Exporter 'import';

sub package_subs {
  no strict 'refs';
  \%{ $_[0].'::_STUFF_SUBS_' }
}

sub package_info {
  no strict 'refs';
  \%{ $_[0].'::_STUFF_SUBS_INFO_' }
}

sub const {
  my( $pkg, $name, $v ) = @_;
  
  # Generate sub.
  my $sub = ref $v eq ''
    ? do { eval qq/sub () { "${\( quotemeta $v )}" } / or die $@ }
    : sub () { $v };
  
  # Place sub.
  {
    local $SIG{__WARN__} = sub {}; # silent "constant subroutine redefined" warnings;
    no strict 'refs';
    *{ "$pkg\::$name" } = $sub;
  }
}

sub set_autoexport {
  my $pkg = shift;
  package_subs( $pkg )->{$_} = 1 for @_;
}

sub unset_autoexport {
  my $pkg = shift;
  package_subs( $pkg )->{$_} = 0 for @_;
}

sub make {
  my( $pkg, $name, $v ) = @_;
  
  $name =~ s/^-//;
  
  if( ref $v eq 'CODE' ) {
    # Respect prototypes.
    my $proto = prototype $v;
    $proto = "($proto)" if defined $proto;
    
    # Generate code.
    my $code = qq{
      package $pkg;
      sub $proto {
        unshift \@_, __PACKAGE__
          unless \@_ && UNIVERSAL::isa( \$_[0], __PACKAGE__ );
        
        return &\$v( \@_ );
      }
    };
    
    # Compile code.
    my $sub = eval $code;
    die $@ if $@;
    
    # Place sub.
    no strict 'refs';
    *{ "$pkg\::$name" } = $sub;
    
    # Remember original code to generate sub in child classes.
    package_subs( $pkg )->{ $name } = $v;
  }
  else {
    const( $pkg, $name, $v );
    
    # Mark sub to be copied.
    package_subs( $pkg )->{ $name } = 1;
  }
  
  return;
}

sub inherit {
  my $to = shift;
  
  no strict 'refs';
  
  my $to_subs = package_subs( $to );
  
  my %skip;
  for my $from( @_ ) {
    my $from_subs = package_subs( $from );
    
    for my $name( keys %$from_subs ) {
      next if $skip{$name};
      
      my $v = $from_subs->{$name};
      
      if( ref $v eq 'CODE' ) {
        make( $to, $name, $v );
      }
      else {
        *{ "$to\::$name" } = \&{ "$from\::$name" };
        $to_subs->{ $name } = 1;
      }
      
      $skip{$name} = 1;
    }
    
    if( package_info( $from )->{mixin} ) {
      for my $name( keys %{"$from\::"} ) {
        next if $name =~ /::$/;
        next if $skip{$name};
        
        if( *{ "$from\::$name" }{CODE} ) {
          *{ "$to\::$name" } = \&{ "$from\::$name" };
          $skip{$name} = 1;
        }
      }
    }
  }
}

sub remove {
  my $pkg = shift;
  
  no strict 'refs';
  
  while( @_ ) {
    my $name = shift;
    $name =~ s/^-//;
    
    undef &{ "$pkg\::$name" };
    delete package_subs( $pkg )->{ $name };
  }
}

1;

=head1 NAME

Stuff::Subs - Autoexported subroutines stuff

=head1 FUNCTIONS

=head2 C<inherit>

  Stuff::Subs::inherit( $package, @bases );

Imports subs from @bases packages. Subs must marked for export with C<set_autoexport> or created with C<make>.

=head2 C<set_autoexport>

  Stuff::Subs::set_autoexport( $package, @names );

=head2 C<unset_autoexport>

  Stuff::Subs::unset_autoexport( $package, @names );

=head2 C<make>

  Stuff::Subs::make( $package, $name => $value );

Defines a autoexported function or constant in package C<$package> that will be exported into
child package with C<inherit>.

C<Stuff::Subs::make> adds package name (or object) the function was called from to arguments of created function when it's called.

  package MyPackage;
  use Stuff::Base -Object;
  
  Stuff::Subs::make( __PACKAGE__, fn => sub { print join ' ' => @_; } );
  
  fn( 'test' ); => "MyPackage test";
  MyPackage->fn( 'test' ); => "MyPackage test";
  MyPackage->new->fn( 'test' ); => "MyPackage=HASH(...) test";

  package AnotherPackage;
  # use Stuff::Base 'MyPackage';
  BEGIN {
    Stuff::Subs::inherit( __PACKAGE__, 'MyPackage' );
  }
  
  fn( 'test' ); => "AnotherPackage test";
  AnotherPackage->fn( 'test' ); => "AnotherPackage test";

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
