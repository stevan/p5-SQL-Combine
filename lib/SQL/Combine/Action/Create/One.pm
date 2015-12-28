package SQL::Combine::Action::Create::One;
use Moose;

use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Upsert;

use SQL::Combine::Query::Insert::RawSQL;

with 'SQL::Combine::Action::Create';

has 'id_key' => ( is => 'ro', isa => 'Str', default => 'id' );

has 'query' => (
    is       => 'ro',
    isa      => 'Object | CodeRef',
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

    my $query = $self->prepare_query( $result );
    my $sth   = $self->execute_query( $query );

    my $last_insert_id = $query->locate_id( $self->id_key )
        // $self->schema
                ->get_rw_dbh
                ->last_insert_id( undef, undef, undef, undef, {} );

    my $hash = { id => $last_insert_id };
    my $rels = $self->execute_relations( $hash );

    return $self->merge_results_and_relations( $hash, $rels );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
