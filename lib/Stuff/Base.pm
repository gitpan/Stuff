package Stuff::Base;

use Stuff::Features;
use Stuff::Defs qw/ def inherit_defs /;
use Stuff::Util qw/ is_package_name load_module /;
use Carp;

# require Stuff::Exception;

sub relative_package {
  my( $package, $num, $relative ) = @_;
  $package =~ s/(?:^|::)[^:]+:*$//;
  "$package\::$relative";
}

sub extend {
  my $package = shift;
  my $options = ref $_[0] eq 'HASH' ? shift : {};
  
  no strict 'refs';
  
  # Configurable namespace.
  my $namespace = $options->{namespace} || 'Stuff::Base';
  is_package_name( $namespace ) or croak( qq/Bad namespace "$namespace"/ );
  $namespace .= '::';
  
  my @bases;
  
  for my $base( map { split( /\s+/, $_ ) } @_ ) {
    $base =~ s/:+$//;
    
    # Short base classes.
    if( $base =~ s/^-// ) {
      $base = $namespace.$base;
    }
    # Relative base class.
    elsif( $base =~ /^(\.+)(.*)/ ) {
      $base = relative_package( $package, length $1, $2 );
    }
    
    if( $base->isa( $package ) ) {
      croak( qq/Package "$package" is trying to inherit from self or own child "$base"/ );
    }
    
    next if grep { $_->isa( $base ) } ( $package, @bases );
    
    if( !defined ${ $base.'::VERSION' } ) {
      my $loaded = load_module( $base, $options->{exception_handler} || \&Stuff::Exception::rethrow );
      
      if( !grep { !/::$/ } keys %{"$base\::"} ) {
        if( $loaded ) {
          croak( qq/Module "$base" loaded but corresponding package is empty/ );
        }
        else {
          croak( qq/Base package "$base" is empty and corresponding module not found. Check for typo or load file with required package/ );
        }
      }
      
      ${ $base.'::VERSION' } = "-1, set by ".__PACKAGE__
        if !defined ${ $base.'::VERSION' };
    }
    
    push @bases, $base;
  }
  
  if( @bases ) {
    my $isa = \@{ "$package\::ISA" };
    
    for( @bases ) {
      push @$isa, $_;
      inherit_defs( $_, $package );
    }
  }
  
  def( $package, def => \&def );
}

sub import {
  shift;
  extend( scalar caller, @_ );
}

1;

=head1 NAME

Stuff::Base - Right inheritance

=head1 SYNOPSIS

  use Stuff::Base @args;

is equvalent to

  BEGIN {
    Stuff::Base::extend( __PACKAGE__, @args );
  }

=head1 FUNCTIONS

=head2 C<extend>

  Stuff::Base::extend( $package, @base_packages );
  Stuff::Base::extend( $package, \%options, @base_packages );

Adds C<@base_packages> to C<$package>'s ISA packages and inherit defs from C<@base_packages>.

=head2 C<def>

An alias for Stuff::Defs::def

=head1 SEE ALSO

L<Stuff>, L<Stuff::Defs>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
