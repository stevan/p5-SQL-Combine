package SQL::Combine::Store;
use Moose::Role;

with 'SQL::Combine';

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Store]',
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
