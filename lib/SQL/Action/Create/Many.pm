package SQL::Action::Create::Many;
use Moose;

with 'SQL::Action::Create';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Composer::Insert] | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbm, $result) = @_;

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @ids;
    foreach my $composer ( @$queries ) {

        my $sql  = $composer->to_sql;
        my @bind = $composer->to_bind;

        my $dbh = $dbm->rw( $self->schema );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        push @ids => $dbh->last_insert_id( undef, undef, undef, undef, {} );
    }

    my $hash = { ids => \@ids };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
