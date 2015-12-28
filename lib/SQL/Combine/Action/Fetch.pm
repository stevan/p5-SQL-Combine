package SQL::Combine::Action::Fetch;
use Moose::Role;

use SQL::Combine::Query::Select;
use SQL::Combine::Query::Select::RawSQL;

with 'SQL::Combine::Action';

has 'query' => (
    is       => 'ro',
    isa      => 'Object | CodeRef',
    required => 1,
);

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE'
}

sub prepare_query {
    my ($self, $result) = @_;
    my $query = $self->query;
    $query = $query->( $result ) if ref $query eq 'CODE';
    return $query;
}

no Moose::Role; 1;

__END__

=pod

=cut
