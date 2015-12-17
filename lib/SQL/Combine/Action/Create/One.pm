package SQL::Combine::Action::Create::One;
use Moose;

use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Upsert;

use SQL::Combine::Query::Insert::RawSQL;

with 'SQL::Combine::Action::Create';

has 'query' => (
    is       => 'ro',
    isa      => (join ' | ' => qw[
                    SQL::Combine::Query::Insert
                    SQL::Combine::Query::Upsert
                    SQL::Combine::Query::Update
                    SQL::Combine::Query::Insert::RawSQL
                    CodeRef
                ]),
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

    my $last_insert_id = $query->id // $self->schema
                                            ->get_rw_dbh
                                            ->last_insert_id( undef, undef, undef, undef, {} );

    my $hash = { id => $last_insert_id };

    my $relations = $self->execute_relations( $hash );

    return { %$hash, %$relations };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
