package SQL::Combine::Action::Fetch::One;
use Moose;

with 'SQL::Combine::Action::Fetch';

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->query;
    $query = $query->( $result )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_ro_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my ($rows) = $sth->fetchall_arrayref;
    return unless @$rows;

    my ($hash) = @{ $query->from_rows($rows) };

    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $hash->{ $rel } = $relations{ $rel }->execute( $hash );
    }

    my $obj = $self->has_inflator ? $self->inflator->( $hash ) : $hash;

    return $obj;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
