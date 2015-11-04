package SQL::Action::Create;
use Moose::Role;

use SQL::Action::Types;

with 'SQL::Action';

has '_relations' => (
    traits   => [ 'Hash' ],
    init_arg => undef,
    is       => 'ro',
    isa      => 'HashRef[SQL::Action::Create]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        create_related => 'set',
        all_relations => 'elements'
    }
);

no Moose::Role; 1;

__END__

=pod

=cut
