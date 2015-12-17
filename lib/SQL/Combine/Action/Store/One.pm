package SQL::Combine::Action::Store::One;
use Moose;

with 'SQL::Combine::Action::Store';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Query::Update | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE';
}

sub prepare_query {
    my ($self, $result) = @_;
    my $query = $self->query;
    $query = $query->( $result ) if ref $query eq 'CODE';
    return $query;
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $sth  = $self->execute_query( $self->prepare_query( $result ) );
    my $hash = { rows => $sth->rows };
    my $rels = $self->execute_relations( $hash );

    return $self->merge_results_and_relations( $hash, $rels );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
