package SQL::Combine::Action::Store;
use Moose::Role;

with 'SQL::Combine::Action';

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Action::Store]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        store_related => 'set',
        all_relations => 'elements'
    }
);

no Moose::Role; 1;

__END__

=pod

=cut
