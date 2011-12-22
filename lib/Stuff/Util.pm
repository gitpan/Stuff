package Stuff::Exception;

use Stuff;
use Stuff::Exception;

sub load_module($) {
  Stuff::load( $_[0], \&Stuff::Exception::rethrow );
}

1;
