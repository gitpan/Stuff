package Stuff::Reload;

use Stuff -Object;

# .
has -paths;
has -namespaces;

# Handlers.
has -on_errors;
has -on_before_unload;
has -on_after_unload;

sub _check_files {
  my( $self ) = @_;
  
  foreach my $m( sort keys %INC ) {
    
  }
  
}

sub _match_path {
  my( $self, $path ) = @_;
  
  $self->paths;
}

sub _match_namespace {
  my( $self, $package ) = @_;
  
  
}

sub run_handler {
  my $self = shift;
  my $name = shift;
  my $code = $self->$name;
  
  if( ref $code eq 'CODE' ) {
    eval { $code->( @_ ); };
  }
}

sub unload_package {
  my( $self, $package ) = @_;
  
  no strict 'refs';
  my @with = @{ "$package\::UNLOAD_WITH" };
  
  $self->clear_package( $package );
  $self->unload_package( $_ ) for @with;
}

sub clear_package {
  my( $self, $package ) = @_;
  
  warn qq/$$ Stuff::Reload: Clearing "$package"\n/;
  
  no strict 'refs';
  
  my $e = \%{ $package . '::' };
  %$e = map { $_ => $e->{$_} } grep { /::$/ } keys %$e;
}

1;
