package Stuff::Export;

use Stuff;
use Exporter;

sub import {
  my $self = shift;
  my $caller = caller;
  
  no strict 'refs';
  
  if( !$caller->isa( 'Exporter' ) ) {
    push @{ "$caller\::ISA" }, 'Exporter';
  }
  
  
  
}

1;
