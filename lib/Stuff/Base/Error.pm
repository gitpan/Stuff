package Stuff::Base::Error;

use Stuff::Features;
use Stuff::Base -Exception;

has message => 'Error!';
has verbose => 1;

1;

=head1 NAME

Stuff::Base::Error - Error exception class

=head1 DESCRIPTION

This is default exception class for Stuff::Exception.

=head1 METHODS

C<Stuff::Base::Error> inherit all methods and attributes from C<Stuff::Base::Exception>.

=head1 SEE ALSO

L<Stuff>, L<Stuff::Exception>, L<Stuff::Base::Exception>

=head1 AUTHOR

Nikita Zubkov E<lt>nikzubkov@gmail.comE<gt>.

=cut
