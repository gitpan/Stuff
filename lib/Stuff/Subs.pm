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

sub set_autoimport {
  my $pkg = shift;
  package_subs( $pkg )->{$_} = 1 for @_;
}

sub unset_autoimport {
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

Stuff::Subs - Special subroutines stuff

=head1 FUNCTIONS

=head2 C<make>

  Stuff::Subs::make( $package, $name => $value );

Defines a function or constant in package C<$package> that will be exported into
child package with C<inherit>.

=head2 C<inherit>

  Stuff::Subs::inherit( $package, @bases );

Import subs from @bases packages. Subs must marked for import with C<autoimported>.

=head2 C<set_autoimport>

  Stuff::Subs::set_autoimport( $package, @names );

=head2 C<unset_autoimport>

  Stuff::Subs::unset_autoimport( $package, @names );

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
