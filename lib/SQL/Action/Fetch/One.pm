package SQL::Action::Fetch::One;
use Moose;

with 'SQL::Action::Fetch';

sub execute {
    my ($self, $dbm, $result) = @_;

    my $composer = $self->composer;
    $composer = $composer->( $result )
        if ref $composer eq 'CODE';

    my $sql  = $composer->to_sql;
    my @bind = $composer->to_bind;

    my $dbh = $dbm->ro( $self->schema );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $rows = $sth->fetchall_arrayref;
    return unless @$rows;

    my ($hash) = @{ $composer->from_rows($rows) };

    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $hash->{ $rel } = $relations{ $rel }->execute( $dbm, $hash );
    }

    my $obj = $self->has_inflator ? $self->inflator->( $hash ) : $hash;

    return $obj;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
