package SQL::Action::Create::One;
use Moose;

with 'SQL::Action::Create';

has 'composer' => (
    is       => 'ro',
    isa      => 'SQL::Composer::Insert | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbm, $result) = @_;

    my $composer = $self->composer;
    $composer = $composer->( $result )
        if ref $composer eq 'CODE';

    my $sql  = $composer->to_sql;
    my @bind = $composer->to_bind;

    my $dbh = $dbm->rw( $self->schema );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $hash = { id => $dbh->last_insert_id( undef, undef, undef, undef, {} ) };

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
