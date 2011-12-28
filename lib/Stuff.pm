package Stuff;

use Stuff::Features;
use Stuff::Base;
use Stuff::Defs qw/ def /;
use Stuff::Exception;

our $VERSION = '0.0.5';

sub import {
  shift;
  Stuff::Base::extend( scalar caller, @_ );
  Stuff::Features->import;
}

1;

=head1 NAME

Stuff - Things perl is missing. Construction kit for applications and frameworks. Be short.

=head1 NOTE

This framework is NOT STABLE yet and API can change without any warning!
Writing of documentation still in progress.

=head1 SYNOPSIS

Frontend to C<Stuff::Features>, C<Stuff::Base> and C<Stuff::Defs>.

  use Stuff @base_packages;

is equivalent to

  use Stuff::Features;
  use Stuff::Base @base_packages;

It is better to use it in your code, instead of C<Stuff::Features>, C<Stuff::Base> and C<Stuff::Defs>.

=head1 SEE ALSO

L<Stuff::Features>, L<Stuff::Base>, L<Stuff::Defs>, L<Stuff::Exception>

=head1 REPOSITORY

L<https://github.com/vokbuz/stuff>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
