package Stuff::Reload;

use Stuff -Object;
use Stuff::Exceptions;

use constant {
  DEBUG => $ENV{STUFF_RELOAD_DEBUG} || 0
};

use constant {
  MODE_DEFAULT => 0,
  MODE_SKIP    => 1,
  MODE_UNLOAD  => 2,
  MODE_RELOAD  => 3,
};

has modes => sub { {} };
has stats => sub { {} };
has custom_files => sub { {} };
has start_time => sub { $^T };
has default_mode => 'reload';

has -paths;
has -namespaces;

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->snapshot( 'skip' );
  $self;
}

sub run {
  my( $self, $cb ) = @_;
  my $modules = $self->check;
  
  if( defined $cb ) {
    die qq/Callback should be coderef/ if ref $cb ne 'CODE';
    
    if( $modules->modified ) {
      eval {
        local $SIG{__DIE__} = \&Stuff::Exceptions::rethrow;
        $cb->( $modules );
      };
      return ref $@ eq 'ARRAY' ? $@ : [$@] if $@;
    }
  }
  else {
    return $modules->reload_safe
      if $modules->modified;
  }
  
  return;
}

sub mode {
  my( $self, $module, $mode ) = @_;
  $self->modes->{ _package_to_module( $module ) } = $self->parse_mode( $mode );
  $self;
}

my %modes_by_name = (
  default => MODE_DEFAULT,
  skip    => MODE_SKIP,
  unload  => MODE_UNLOAD,
  reload  => MODE_RELOAD,
);

sub parse_mode {
  my( $self, $mode ) = @_;
  $modes_by_name{$mode} or die qq/Unknown mode: "$mode"/;
}

sub snapshot {
  my( $self, $mode ) = @_;
  my $modes = $self->modes;
  
  $mode = $mode ? $self->parse_mode( $mode ) : MODE_SKIP;
  
  foreach my $m( sort keys %INC ) {
    next unless $m && $m =~ /\.pm$/;
    next if defined $modes->{$m};
    next if !$self->match_namespace( $m );
    next if !$self->match_path( $INC{$m} );
    
    $modes->{$m} = $mode;
    
    warn "$$ Stuff::Reload: Snapshotting module: $m\n"; 
  }
  
  $self;
}

sub check {
  my $self = shift;
  
  my $stats = $self->stats;
  my $modes = $self->modes;
  
  my( @reload, @unload );
  my $has_modifications = 0;
  my $default_mode = $self->parse_mode( $self->default_mode );
  
  foreach my $m( sort keys %INC ) {
    next unless $m && $m =~ /\.pm$/;
    next if !$self->match_namespace( $m );
    
    my $mode = $modes->{$m} || $default_mode;
    next if $mode == MODE_SKIP;
    
    my $is_modified;
    my( $file, $mtime ) = $self->find_module( $m );
    
    next if $file && !$self->match_path( $file );
    
    if( $mtime ) {
      $is_modified = ( $stats->{$m} || $self->start_time ) < $mtime;
      $stats->{$m} = $mtime;
    }
    else {
      $is_modified = 1;
    }
    
    if( $mode == MODE_RELOAD ) {
      push @reload, $m if $is_modified;
    }
    else {
      push @unload, $m;
    }
    
    if( $is_modified ) {
      warn "$$ Stuff::Reload: Modified file: $m -> $file\n";
      $has_modifications = 1;
    }
  }
  
  $has_modifications = 1 if $self->check_custom;
  
  return Stuff::Reload::Modules->new(
    reloader => $self,
    reload_modules => \@reload,
    unload_modules => \@unload,
    modified => $has_modifications
  );
}

sub find_module {
  my( $self, $module ) = @_;
  
  my $file = $INC{$module};
  my $mtime = length $file ? (stat $file)[9] : undef;
  
  if( !$mtime ) {
    undef $file;
    
    for( @INC ) {
      my $f = "$_/$module";
      my $m = (stat $f)[9];
      
      $file = $f, $mtime = $m, last if $m;
    }
  }
  
  return ( $file, $mtime );
}


sub check_custom {
  my $self = shift;
  
  0;
}

sub match_path {
  my( $self, $path ) = @_;
  1;
}

sub match_namespace {
  my( $self, $package ) = @_;
  1;
}

sub unload_module {
  my( $self, $m ) = @_;
  my $p = _module_to_package( $m );
  delete $INC{$m};
  $self->unload_package( $p );
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

sub _module_to_package {
  my( $str ) = @_;
  $str =~ s/\//::/g;
  $str =~ s/\.pm$//;
  $str;
}

sub _package_to_module {
  my( $str ) = @_;
  $str =~ s/::/\//g;
  $str .= '.pm';
  $str;
}

package Stuff::Reload::Modules;

use Stuff -Object;

has [qw/
  reloader
  modified
  reload_modules
  unload_modules
/];

sub reload {
  my $self = shift;
  my @errors;
  
  my $reload = $self->reload_modules;
  my $unload = $self->unload_modules;
  
  if( $unload ) {
    $self->reloader->unload_module( $_ ) for @$unload;
  }
  
  if( $reload && @$reload ) {
    $self->reloader->unload_module( $_ ) for @$reload;
    
    foreach my $m( @$reload ) {
      next if exists $INC{$m};
      
      eval {
        local $SIG{__DIE__} = \&Stuff::Exceptions::rethrow;
        require $m;
      };
      
      if( $@ ) {
        $INC{$m} = undef;
        push @errors, $@;
      }
    }
  }
  
  return \@errors;
}

1;

__END__
=head1 NAME

Stuff::Reload - Modules unloader and reloader

=head1 SYNOPSIS

  use Stuff::Reload;
  my $reload = Stuff::Reload->new( %args );
  $reload->run;

=head1 METHODS

=head2 C<new>

  my $reload = Stuff::Reload->new( %args );

=head2 C<run>

  my $errors = $modules->run;
  my $errors = $modules->run( sub {
    # callback called when any modification happen
  } );

=head2 C<check>

  my $modules = $reload->check;
  if( $modules->modified ) {
    # Do some finalizing...
    my $errors = $modules->reload_safe;
  }

Method C<check> checks if any of traced modules were changed.
Returns $modules object, which can be used to perform custom reload strategy.

=head1 CODE RELOAD STRATEGIES

=head2 Simple reload

You can simply reload your code when it was modified.
If your modules "pure" (have no side effects at loading) then you can use it.

  # Initialization.
  use Stuff::Reload;
  my $reloader = Stuff::Reload->new;
  
  # ...
  
  # At some point where reload can happen.
  # All modified modules will be reloaded.
  my $errors = $reloader->run;

=head2 Smart code replacing

But the best way to reload code is to use unload and restart application initialization process.

  sub init {
    # initialization code
  }
  
  sub shutdown {
    # shutdown code
  }
  
  use Stuff::Reload;
  my $reloader = Stuff::Reload->new(
    default_mode => 'unload'
  );
  
  init();
  
  # ...
  
  # At some point where reload can happen.
  my $errors = $reloader->run( sub {
    shutdown();
    
    shift->reload;
    
    init();
  } );

=cut
