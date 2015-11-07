package SQL::Combine::Fetch;
use Moose::Role;

use SQL::Combine::Table::Select;

with 'SQL::Combine';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Table::Select | CodeRef',
    required => 1,
);

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Fetch]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        fetch_related => 'set',
        all_relations => 'elements'
    }
);

no Moose::Role; 1;

__END__

=pod

=cut
