package Stuff::Object;

use Stuff::Features;
use Stuff::Base -def;
use Stuff::Util qw/ clone /;

# Attribute maker.
def has => sub { shift->define_attr( @_ ) };

# Constructor.
sub new {
  my $proto = shift;
  my $self = bless {}, ref $proto || $proto;
  
  $self->initialize( @_ );
  $self;
}

sub initialize {
  my $self = shift;
  %$self = UNIVERSAL::isa( $_[0], 'HASH' ) ? %{$_[0]} : @_;
}

sub define_attr {
  # Class name or blessed object.
  my $class = shift;
  $class = ref $class || $class;
  
  # Attribute names.
  my $names = shift;
  
  # Default value and params.
  my( $default, $params );
  
  if( ref $names eq 'HASH' ) {
    $params = $names;
    $names = $params->{name};
    $default = $params->{default};
  }
  else {
    if( @_ % 2 == 0 ) {
      $params = {@_};
      $default = $params->{default};
    }
    else {
      $default = shift;
      $params = {@_};
      $params->{default} = $default;
    }
  }
  
  for( ref $names eq 'ARRAY' ? @$names : $names ) {
    ( my $name = $_ ) =~ s/^-//;
    
    # Check attribute name validity.
    die qq/Bad attribute name: "$name"/
      unless $name =~ /^[a-z_][a-z_0-9]*$/i;
    
    # Generate accessor.
    my $sub = $class->_generate_accessor( $name, $default );
    
    # Create accessor.
    no warnings 'redefine';
    no strict 'refs';
    
    *{ "$class\::$name" } = $sub;
  }
}

sub _generate_accessor {
  my( $self, $name, $default ) = @_;
  
  # Code for default value generator.
  my $default_code = defined $default ? (
    ref $default eq 'CODE' ? '$default->(@_)' :
    ref $default ? 'Stuff::Util::clone( $default )' :
    '$default'
  ) : '';
  
  # Generate accessor code.
  my $code = "";
  
  # Indention.
  my $i = "  "; 
  
  $code .= "sub {\n";
  
  if( $default_code ) {
    $code .= "${i}return exists \$_[0]->{'$name'} ? ( \$_[0]->{'$name'} ) : ( \$_[0]->{'$name'} = $default_code ) if \@_ < 2;\n";
  }
  else {
    $code .= "${i}return \$_[0]->{'$name'} if \@_ < 2;\n";
  }
  
  $code .= "${i}\$_[0]->{'$name'} = \$_[1];\n";
  $code .= "${i}return \$_[0];\n";
  $code .= "};";
  
  # Compile code.
  my $sub = eval $code;
  
  # Handle compilation errors.
  die qq/Accessor compilation error:\n$code\n$@\n/ if $@;
  
  return $sub;
}

1;

=head1 NAME

Stuff::Object - Object class with attributes

=head1 SYNOPSIS

  package Person;
  use Stuff -Object;
  
  has -age;
  has mood => 'Good!';
  
  say Person->new( age => 28 )->age;
  say Person->new->age( 28 )->age;
  say Person->new->mood;
  say Person->new( mood => 'Boring' )->mood;

=head1 METHODS

=head2 C<new>

  $package->new;
  $package->new( \%attrs );
  $package->new( %attrs );

=head2 C<define_attr>

=head2 C<has>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
