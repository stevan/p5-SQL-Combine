package SQL::Action::Create::One;
use Moose;

use SQL::Action::Table::Insert;

with 'SQL::Action::Create';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Action::Table::Op | CodeRef',
    required => 1,
);

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

    my $last_insert_id = $query->has_insert_id
        ? $query->insert_id
        : $dbh->last_insert_id( undef, undef, undef, undef, {} );

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
