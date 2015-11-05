package SQL::Action::Store::One;
use Moose;

with 'SQL::Action::Store';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Composer::Update | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbm, $result) = @_;

    my $query = $self->query;
    $query = $query->( $result )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    my $dbh = $dbm->rw( $self->schema );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $hash = { rows => $sth->rows || 0E0 };

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
