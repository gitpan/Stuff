package Stuff::Base;

use Stuff::Features;
use Stuff::Defs qw/ def inherit_defs /;
use Stuff::Util qw/ is_package_name load_module /;
use Carp;

our $EXCEPTION_HANDLER;

sub relative_package {
  my( $package, $l, $relative ) = @_;
  my @parts = split( /::/, $package );
  
  if( $l > 0 ) {
    splice @parts, $l >= @parts ? 0 : -$l;
  }
  
  join '::', @parts, $relative;
}

sub extend {
  my $package = shift;
  my %options = ref $_[0] eq 'HASH' ? %{shift @_} : ();
  
  no strict 'refs';
  
  # Configurable namespace.
  my $namespace = $options{namespace} || 'Stuff::Base';
  is_package_name( $namespace ) or croak( qq/Bad namespace "$namespace"/ );
  $namespace .= '::';
  
  my @bases;
  
  for my $base( map { split( /\s+/, $_ ) } @_ ) {
    $base =~ s/:+$//;
    
    # Short base classe or option.
    if( $base =~ s/^-// ) {
      if( $base =~ /^[a-z]/ ) {
        $options{$base} = 1;
        next;
      }
      
      $base = $namespace.$base;
    }
    # Relative base class.
    elsif( $base =~ /^(\.+)(.*)/ ) {
      $base = relative_package( $package, length( $1 ) - 1, $2 );
    }
    
    if( $base->isa( $package ) ) {
      croak( qq/Package "$package" is trying to inherit from self or own child "$base"/ );
    }
    
    next if grep { $_->isa( $base ) } ( $package, @bases );
    
    if( !defined ${ $base.'::VERSION' } ) {
      my $loaded = load_module(
        $base,
        $options{exception_handler} || $EXCEPTION_HANDLER || *Stuff::Exception::rethrow{CODE}
      );
      
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
    push @$isa, @bases;
    inherit_defs( $package, @bases ) unless $options{no_defs};
  }
  
  def( $package, def => \&def ) if $options{def};
}

sub import {
  shift;
  extend( scalar caller, @_ );
}

1;

=head1 NAME

Stuff::Base - The right "use base"

=head1 SYNOPSIS

  # Load "MyBase1" and "MyBase2", add them to ISA and
  # import defs from them and their baases.
  use Stuff::Base 'MyBase1 MyBase2';
  
  # Load "Stuff::Base::Object" and add it to ISA,
  # import defs from "Stuff::Base::Object" and its baases.
  use Stuff::Base -Object;
  
  # Import "def" function.
  use Stuff::Base -def;
  
  # Relative bases.
  package Very::Long::Package::Name;
  use Stuff::Base '.Haha';   # use Stuff::Base 'Very::Long::Package::Name::Haha';
  use Stuff::Base '..Haha';  # use Stuff::Base 'Very::Long::Package::Haha';
  use Stuff::Base '...Haha'; # use Stuff::Base 'Very::Long::Haha';
  # .. etc

=head1 FUNCTIONS

=head2 C<extend>

  Stuff::Base::extend( $package, @base_packages );
  Stuff::Base::extend( $package, \%options, @base_packages );

Adds C<@base_packages> to C<$package>'s ISA packages and inherit defs from C<@base_packages>.

  use Stuff::Base @args;

is equvalent to

  BEGIN {
    Stuff::Base::extend( __PACKAGE__, @args );
  }

=head2 C<def>

An alias for Stuff::Defs::def

=head1 IMPORT



=head1 SEE ALSO

L<Stuff>, L<Stuff::Defs>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
