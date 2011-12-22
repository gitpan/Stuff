package Stuff::Base::Exception;

use Stuff -Object;
use Stuff::ExceptionFrame;
use Scalar::Util qw/ refaddr /;
use overload
  bool => sub { 1 },
  '""' => 'to_string',
  fallback => 1;

has -message;
has -frames => sub { [] };
has -no_frames => 0;

sub to_string {
  my $self = shift;
  ''.$self->{message}
}

sub new {
  my $self = shift->SUPER::new( ( @_ == 1 && !ref $_[0] ) ? ( message => $_[0] ) : @_ );
  my $no_frames = $self->is_expected || $self->no_frames;
  
  $self->_collect_frames
    unless $no_frames;
  
  return $self;
}

sub is_expected {
  $Stuff::Exception::expected{ ref $_[0] };
}

sub throw {
  my $proto = shift;
  die ref $proto ? $proto : $proto->new( @_ );
}

sub _collect_frames {
  my( $self ) = @_;
  
  my @frames;
  for( my $i = 2; ; $i++ ) {
    my @c = caller( $i ) or last;
    push @frames, Stuff::ExceptionFrame->new( [ (@c)[0..7] ] );
  }
  
  $self->frames( \@frames );
}

1;
