package Stuff::Error;

use Stuff::Features;
use Stuff::Base -Exception;

has message => 'Error!';

1;

=head1 NAME

Stuff::Error - Error exception class

=head1 DESCRIPTION

This is default exception class for Stuff::Exception.

=head1 METHODS

C<Stuff::Error> inherit all methods and attributes from C<Stuff::Exception>.

=head1 SEE ALSO

L<Stuff>, L<Stuff::Exceptions>, L<Stuff::Exception>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
