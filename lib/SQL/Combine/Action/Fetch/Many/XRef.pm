package SQL::Combine::Action::Fetch::Many::XRef;
use Moose;

with 'SQL::Combine::Action::Fetch';

has 'xref_query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Query::Select | CodeRef',
    required => 1,
);

has '+query' => ( isa => 'CodeRef' );

sub is_static { return 0 }

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $xref_results;
    {
        my $xref_query = $self->xref_query;
        $xref_query = $xref_query->( $result )
            if ref $xref_query eq 'CODE';

        my $sql  = $xref_query->to_sql;
        my @bind = $xref_query->to_bind;

        $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
            && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

        # NOTE:
        # We run the xref query on the
        # same DBH, this might not be
        # sensible, so think it through
        # - SL
        my $dbh = $self->schema->get_ro_dbh;
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        my @rows = $sth->fetchall_arrayref;
        return unless @rows;

        $xref_results = $xref_query->from_rows(@rows);
        return unless @$xref_results;
    }

    my $query = $self->query;
    $query = $query->( $xref_results )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_ro_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my @rows = $sth->fetchall_arrayref;
    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my %relations = $self->all_relations;
    foreach my $hash ( @$hashes ) {
        foreach my $rel ( keys %relations ) {
            $hash->{ $rel } = $relations{ $rel }->execute( $hash );
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
