package SQL::Action::Store::Many;
use Moose;

with 'SQL::Action::Store';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Composer::Update] | CodeRef',
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

        push @ids => ($sth->rows || 0E0);
    }

    my $hash = { rows => \@ids };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
