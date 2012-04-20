package Stuff::Base;

use Stuff::Features;
use Stuff::Util;
use Carp;
use Data::Dumper;

our $EXCEPTION_HANDLER;

sub package_subs {
  no strict 'refs';
  \%{ $_[0].'::_STUFF_SUBS_' }
}

sub package_info {
  no strict 'refs';
  \%{ $_[0].'::_STUFF_INFO_' }
}

sub make_sub {
  my( $pkg, $name, $v ) = @_;
  
  no strict 'refs';
  
  $name =~ s/^-//;
  
  if( ref $v eq 'CODE' ) {
    my $proto = prototype $v;
    $proto = "($proto)" if defined $proto;
    
    my $code = qq{
      package $pkg;
      sub $proto {
        unshift \@_, __PACKAGE__
          unless \@_ && UNIVERSAL::isa( \$_[0], __PACKAGE__ );
        
        return &\$v( \@_ );
      }
    };
    
    # warn "$name: $code";
    *{ "$pkg\::$name" } = eval( $code ) || die $@;
    
    package_subs( $pkg )->{$name} = $v;
  }
  else {
    local $SIG{__WARN__} = sub {};
    
    if( ref $v eq '' ) {
      my $code = qq/sub () { "${\( quotemeta $v )}" }/;
      # warn "$name: $code";
      *{ "$pkg\::$name" } = eval( $code ) || die $@;
    }
    else {
      *{ "$pkg\::$name" } = sub () { $v };
    }
    
    package_subs( $pkg )->{$name} = 1;
  }

  return;
}

sub import_subs {
  my $to = shift;
  
  no strict 'refs';
  
  my $to_subs = package_subs( $to );
  
  my %seen;
  for my $from( @_ ) {
    my $from_subs = package_subs( $from );
    
    for my $name( keys %$from_subs ) {
      next if $seen{$name};
      
      my $v = $from_subs->{$name};
      
      if( ref $v eq 'CODE' ) {
        make_sub( $to, $name, $v );
      }
      else {
        *{ "$to\::$name" } = \&{ "$from\::$name" };
        $to_subs->{ $name } = 1;
      }
      
      $seen{$name} = 1;
    }
    
    if( package_info( $from )->{mixin} ) {
      for my $name( keys %{"$from\::"} ) {
        next if $name =~ /::$/;
        next if $seen{$name};
        
        if( *{ "$from\::$name" }{CODE} ) {
          *{ "$to\::$name" } = \&{ "$from\::$name" };
          $seen{$name} = 1;
        }
      }
    }
  }
}

sub set_autoexported {
  my $pkg = shift;
  package_subs( $pkg )->{$_} = 1 for @_;
}

sub unset_autoexported {
  my $pkg = shift;
  package_subs( $pkg )->{$_} = 0 for @_;
}

sub relative_package {
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
  my @bases;
  
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
      $base = relative_package( $package, length( $1 ) - 1, $2 );
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
    
    push @bases, $base;
  }
  
  if( $flags{mixin} ) {
    package_info( $package )->{mixin} = 1;
  }
  
  if( $flags{def} ) {
    make_sub( $package, def => \&make_sub );
  }
  
  if( @bases ) {
    import_subs( $package, @bases );
    push @{ "$package\::ISA" }, grep { !package_info( $_ )->{mixin} } @bases;
  }
}

sub import {
  shift;
  extend( scalar caller, @_ );
}

1;

__END__
=head1 NAME

Stuff::Base - The right "use base"

=head1 SYNOPSIS

  # Load "MyBase1" and "MyBase2", add them to ISA and
  # import defs from them and their baases.
  use Stuff::Base 'MyBase1 MyBase2';
  
  # Load "Stuff::Object" and add it to ISA,
  # import defs from "Stuff::Object" and its baases.
  use Stuff::Base -Object;
  
  # Import "def" function.
  use Stuff::Base -def;
  
  # Relative bases.
  package Very::Long::Package::Name;
  use Stuff::Base '.Haha';   # same as: use Stuff::Base 'Very::Long::Package::Name::Haha';
  use Stuff::Base '..Haha';  # same as: use Stuff::Base 'Very::Long::Package::Haha';
  use Stuff::Base '...Haha'; # same as: use Stuff::Base 'Very::Long::Haha';
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

=head2 C<make_sub>

  Stuff::Base::make_sub( $package, $name => $value );

Defines a autoexported function or constant in package C<$package> that will be exported into
child package with C<import_subs> or C<extend> (which calls C<import_subs>).

C<Stuff::Base::make_sub> adds package name (or object) the function was called from to arguments of created function when it's called.

  package MyPackage;
  use Stuff::Base -Object;
  
  # This is just an example, better use C<def fn => sub { print join ' ' => @_; }>.
  Stuff::Base::make_sub( __PACKAGE__, fn => sub { print join ' ' => @_; } );
  
  fn( 'test' ); => "MyPackage test";
  MyPackage->fn( 'test' ); => "MyPackage test";
  MyPackage->new->fn( 'test' ); => "MyPackage=HASH(...) test";

  package AnotherPackage;
  # use Stuff::Base 'MyPackage';
  BEGIN {
    Stuff::Base::extend( __PACKAGE__, 'MyPackage' );
    # or
    # Stuff::Base::import_subs( __PACKAGE__, 'MyPackage' );
  }
  
  fn( 'test' ); => "AnotherPackage test";
  AnotherPackage->fn( 'test' ); => "AnotherPackage test";

=head2 C<set_autoexported>

  Stuff::Base::set_autoexported( $package, @names );

Marks C<@names> in package C<$package> as autoexported, so C<import_sub> will import them in child class.

=head2 C<unset_autoexported>

  Stuff::Base::unset_autoexported( $package, @names );

Marks C<@names> in package C<$package> as not autoexported, so C<import_sub> will not import them in child class.

=head1 IMPORT

=head2 C<def>

  use Stuff::Base -def;

This will add to caller "def" function. Which is a wrapper for C<Stuff::Base::make_sub>.

  package My;
  use Stuff::Base -def;
  
  # The following two lines are equivalent:
  def a => sub { ... };
  Stuff::Base::make_sub( __PACKAGE__, sub { ... } );

=head1 SEE ALSO

L<Stuff>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
