package Stuff;

use Stuff::Features;
use Carp ();

our $VERSION = '0.0.2';

sub def {
  my( $pkg, $name, $v ) = @_;
  
  no strict 'refs';
  
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
    
    # Create named sub.
    *{ "$pkg\::$name" } = $sub;
    
    # Remember original code to generate defs in child classes.
    _defs( $pkg )->{ $name } = $v;
  }
  else {
    local $SIG{__WARN__} = sub {}; # no warnings;
    
    # Constant defs become constants.
    *{ "$pkg\::$name" } =
      ref $v eq '' ? do { eval qq/sub () { "${\( quotemeta $v )}" } / or die $@ } :
      sub () { $v };
    
    # Don't remember code cuz if we are it will be wrapped in inherit_defs.
    _defs( $pkg )->{ $name } = 1;  
  }
  
  return;
}

sub inherit_defs {
  my( $from, $to ) = @_;
  
  no strict 'refs';
  
  my $from_defs = _defs( $from );
  
  # For each def in $from package.
  for my $name( keys %$from_defs ) {
    
    # Skip if sub already exists.
    next if defined *{ "$to\::$name" }{CODE};
    
    my $v = $from_defs->{$name};
    
    if( ref $v eq 'CODE' ) {
      # Rewrap def.
      def( $to, $name, $from_defs->{$name} );
    }
    else {
      # Make an alias for constants.
      *{ "$to\::$name" } = \&{ "$from\::$name" };
      _defs( $to )->{ $name } = 1;
    }
  }
}

sub _defs {
  no strict 'refs';
  \%{ $_[0].'::_STUFF_DEFS_' }
}

sub _relative_package {
  my( $package, $relative ) = @_;
  $package =~ s/(?:^|::)[^:]+:*$//;
  "$package\::$relative";
}

sub extend {
  my $package = shift;
  my %options;
  
  no strict 'refs';
  
  my @bases;
  for my $base( map { split( /\s+/, $_ ) } @_ ) {
    # Options or short base classes.
    if( $base =~ s/^-// ) {
      $base = 'Stuff::Base::'.$base;
    }
    # Relative base class.
    elsif( $base =~ /^::(.*)/ ) {
      $base = _relative_package( $package, $1 );
    }
    
    $base =~ s/:+$//;
    
    if( $base->isa( $package ) ) {
      Carp::croak( qq/Package "$package" is trying to inherit from self or own child "$base"/ );
    }
    
    next if grep { $_->isa( $base ) } ( $package, @bases );
    
    if( !defined ${ $base.'::VERSION' } ) {
      my $loaded = load( $base );
      
      if( !grep { !/::$/ } keys %{"$base\::"} ) {
        if( $loaded ) {
          Carp::croak( qq/Module "$base" loaded but corresponding package is empty/ );
        }
        else {
          Carp::croak( qq/Base package "$base" is empty and corresponding module not found. Check for typo or load file with required package/ );
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

sub load($;$) {
  my( $package, $dh ) = @_;
  
  my $module = $package;
  $module =~ s/::|\'/\//g;
  $module .= '.pm';
  
  eval {
    local $SIG{__DIE__} = $dh if $dh;
    
    Carp::croak( qq/Empty package name/ )
      unless length $package;
    
    Carp::croak( qq/Bad package name "$package"/ )
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

sub import {
  shift;
  extend( scalar caller, @_ );
  Stuff::Features->import;
}

1;

=head1 NAME

Stuff - Things perl is missing. Construction kit for applications and frameworks.

=head1 SYNOPSIS

  use Stuff;
  use Stuff qw/ BaseClass1 BaseClass2 /;
  use Stuff 'BaseClass1 BaseClass2'; # yeah! single string - multiple modules
  use Stuff -Object; # => use Stuff qw/ Stuff::Object /;

  package BaseClass;
  use Stuff;
  def x => 10;
  def hello => sub { print "I'm called from $_[0] with argument $_[1]" };
  hello( 1 );
  
  package SomeClass;
  use Stuff qw/ BaseClass /;
  print x;
  hello( 2 );

=head1 DESCRIPTION

  use Stuff;
  use Stuff @base_packages;

Features from C<Stuff::Features> exported into caller code.
Loads C<@base_packages> and adds them to caller's ISA and inherit defs from them.

=head1 FUNCTIONS

=head2 C<def>

  Stuff::def( $package, 'name' => $value );
  Stuff::def( $package, -name  => $value );

Defines a function or constant in package C<$package> that will be exported into
child package with C<use Stuff> or C<<Stuff->import>>.

=head2 C<extend>

  Stuff::extend( $package, @base_packages );

Adds C<@base_packages> to C<$package>'s ISA packages and inherit defs from C<@base_packages>.

=head2 C<load>

  Stuff::load( $module [, $exception_converter] );

Loads module by its name (e.g. 'Some::Module').
If module can't be found, returns empty list or undef.
If module loads normally or been loaded before, returns 1.
If any error happen duering loading, this error will be thrown.

Second optional argument defines "error handler" or "exception converter".
The only purpose for it is conversion of standart perl error into your custom error object. Like this:

  use Scalar::Util 'blessed';
  
  Stuff::load( $module, sub {
    $@->rethrow if blessed $@;
    $exception_class->throw( $@ );
  } );

=head1 SEE ALSO

L<Stuff::Features>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
