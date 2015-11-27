package SQL::Combine::Action::Fetch;
use Moose::Role;

use SQL::Combine::Query::Select;

with 'SQL::Combine::Action';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Query::Select | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE'
}

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Action::Fetch]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        _add_relation => 'set',
        all_relations => 'elements'
    }
);

sub fetch_related {
    my ($self, $name, $action) = @_;
    $self->_add_relation( $name, $action );
    $self;
}

no Moose::Role; 1;

__END__

=pod

=cut
