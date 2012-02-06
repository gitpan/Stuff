package Stuff::Base;

use Stuff::Features;
use Stuff::Subs;
use Stuff::Util;
use Carp;
use Data::Dumper;

our $EXCEPTION_HANDLER;

sub _relative_package {
  my( $package, $l, $relative ) = @_;
  my @parts = split( /::/, $package );
  
  if( $l > 0 ) {
    splice @parts, $l >= @parts ? 0 : -$l;
  }
  
  join '::', @parts, $relative;
}

sub extend {
  no strict 'refs';
  
  my $package = shift;
  my %flags;
  my( @all, @bases );
  
  for my $base( map { split( /\s+/, $_ ) } @_ ) {
    $base =~ s/:+$//;
    $base =~ s/^:+//;
    
    # Short base classe or flag.
    if( $base =~ s/^-// ) {
      if( $base =~ /^[a-z]/ ) {
        $flags{$base} = 1;
        next;
      }
      
      $base = 'Stuff::'.$base;
    }
    # Relative base class.
    elsif( $base =~ /^(\.+)(.*)/ ) {
      $base = _relative_package( $package, length( $1 ) - 1, $2 );
    }
    
    if( $base->isa( $package ) ) {
      croak( qq/Package "$package" is trying to inherit from self or own child "$base"/ );
    }
    
    next if grep { $_->isa( $base ) } ( $package, @bases );
    
    if( !defined ${ $base.'::VERSION' } ) {
      my $loaded = Stuff::Util::load_module(
        $base,
        $EXCEPTION_HANDLER || *Stuff::Exceptions::rethrow{CODE}
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
    
    push @all, $base;
    push @bases, $base unless Stuff::Subs::package_info( $base )->{mixin};
  }
  
  if( $flags{mixin} ) {
    # Mark package as a mixin.
    Stuff::Subs::package_info( $package )->{mixin} = 1;
  }
  
  push @{ "$package\::ISA" }, @bases;
  
  Stuff::Subs::inherit( $package, @all );
  
  if( $flags{def} ) {
    Stuff::Subs::make( $package, def => \&Stuff::Subs::make );
  }
  
  if( $flags{c3} ) {
    require mro;
    mro::set_mro( $package => 'c3' );
  }
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

Adds C<@base_packages> to C<$package>'s ISA list and imports autoimported subs from C<@base_packages>.

  use Stuff::Base @args;

is equvalent to

  BEGIN {
    Stuff::Base::extend( __PACKAGE__, @args );
  }

=head1 IMPORT



=head1 SEE ALSO

L<Stuff>, L<Stuff::Subs>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
