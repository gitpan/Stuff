package Stuff::Defs;

use Stuff::Features;
use Exporter 'import';

our @EXPORT_OK = qw/ def inherit_defs /;

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
    
    # Place sub.
    *{ "$pkg\::$name" } = $sub;
    
    # Remember original code to generate defs in child classes.
    _defs( $pkg )->{ $name } = $v;
  }
  else {
    # Generate sub.
    my $sub = ref $v eq ''
        ? do { eval qq/sub () { "${\( quotemeta $v )}" } / or die $@ }
        : sub () { $v };
    
    # Place sub.
    {
      local $SIG{__WARN__} = sub {}; # silent prototype mismatch warnings;
      *{ "$pkg\::$name" } = $sub;
    }
    
    # Mark def to be copied.
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

1;

=head1 NAME

Stuff::Defs

=head1 WHAT IS IT?

"Defs" are designed for easy DSL (domain specific language) creation.
Here is an example of DSL for database model's table.

  # BaseModel.pm
  package BaseModel;
  use Stuff;
  
  # Default value for table.
  def table => sub() {
    my $pkg = ref $_[0] || $_[0];
    $pkg =~ s/.*::([^:]+)(?:::)?$/$1/;
    $pkg =~ s/Model$//;
    return lc $pkg;
  };
  
  # Set custom value for table.
  def set_table => sub {
    Stuff::def $_[0], 'table', $_[1];
  };
  1;

  # MessageModel.pm
  package MessageModel;
  use Stuff 'BaseModel';
  1;

  # UserModel.pm
  package UserModel;
  use Stuff 'BaseModel';
  set_table 'account';
  1;

  # Test it.
  use Test::More tests => 4;
  use UserModel;
  use MessageModel;
  is( UserModel->table, 'account' );
  is( UserModel::table, 'account' );
  is( MessageModel->table, 'message' );
  is( MessageModel::table, 'message' );

L<Stuff::Base::Object>'s C<has> is a def.

=head1 FUNCTIONS

=head2 C<def>

  def( $package, 'name' => $value );
  def( $package, -name  => $value );

Defines a function or constant in package C<$package> that will be exported into
child package with C<inherit_defs>.

=head2 C<inherit_defs>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
