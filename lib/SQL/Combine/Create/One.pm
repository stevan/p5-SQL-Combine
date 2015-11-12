package SQL::Combine::Create::One;
use Moose;

use SQL::Combine::Table::Insert;
use SQL::Combine::Table::Upsert;

with 'SQL::Combine::Create';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Table::Insert | SQL::Combine::Table::Upsert | SQL::Combine::Table::Update | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE';
}

sub execute {
    my ($self, $dbm, $result) = @_;

    my $query = $self->query;
    $query = $query->( $result )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    my $dbh = $dbm->rw( $query->table->schema );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $last_insert_id = $query->id // $dbh->last_insert_id( undef, undef, undef, undef, {} );

    my $hash = { id => $last_insert_id };

    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $hash->{ $rel } = $relations{ $rel }->execute( $dbm, $hash );
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
