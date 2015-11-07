package SQL::Combine::Fetch::Many::XRef;
use Moose;

with 'SQL::Combine::Fetch';

has 'xref_query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Table::Select | CodeRef',
    required => 1,
);

has '+query' => ( isa => 'CodeRef' );

sub execute {
    my ($self, $dbm, $result) = @_;

    my $xref_results;
    {
        my $xref_query = $self->xref_query;
        $xref_query = $xref_query->( $result )
            if ref $xref_query eq 'CODE';

        my $sql  = $xref_query->to_sql;
        my @bind = $xref_query->to_bind;

        my $dbh = $dbm->ro( $xref_query->table->schema );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        my @rows = $sth->fetchall_arrayref;
        return unless @rows;

        $xref_results = $xref_query->from_rows(@rows);
    }

    my $query = $self->query;
    $query = $query->( $xref_results )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    my $dbh = $dbm->ro( $query->table->schema );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my @rows = $sth->fetchall_arrayref;
    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my %relations = $self->all_relations;
    foreach my $hash ( @$hashes ) {
        foreach my $rel ( keys %relations ) {
            $hash->{ $rel } = $relations{ $rel }->execute( $dbm, $hash );
        }
    }

    my $objs = $self->has_inflator ? $self->inflator->( $hashes ) : $hashes;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
