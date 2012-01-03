package Stuff;

use Stuff::Features;
use Stuff::Base;

our $VERSION = '0.0.8';

sub import {
  shift;
  Stuff::Base::extend( scalar caller, @_ );
  Stuff::Features->import;
}

1;

=head1 NAME

Stuff - Object oriented programming framework

=head1 NOTE

This framework is NOT STABLE yet and API can change without any warning!
Writing of documentation still in progress.

=head1 SYNOPSIS

Frontend to C<Stuff::Features>, C<Stuff::Base> and C<Stuff::Defs>.

  use Stuff @args;

is equivalent to

  use Stuff::Features;
  use Stuff::Base @args;

It is better to use C<use Stuff> in your code, instead of separate C<Stuff::Features>, C<Stuff::Base> and C<Stuff::Defs>.

=head1 SEE ALSO

L<Stuff::Features>, L<Stuff::Base>, L<Stuff::Defs>, L<Stuff::Exception>

=head1 REPOSITORY

L<https://github.com/vokbuz/p5-stuff>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>

=cut
