package SQL::Action::Fetch;
use Moose::Role;

use SQL::Action::Types;

with 'SQL::Action';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Composer::Select | CodeRef',
    required => 1,
);

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

has '_relations' => (
    traits   => [ 'Hash' ],
    init_arg => undef,
    is       => 'ro',
    isa      => 'HashRef[SQL::Action::Fetch]',
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
