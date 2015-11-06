package SQL::Action::Create::Many;
use Moose;

use SQL::Action::Table::Insert;
use SQL::Action::Table::Upsert;
use SQL::Action::Table::Update;

with 'SQL::Action::Create';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[ SQL::Action::Table::Insert | SQL::Action::Table::Upsert | SQL::Action::Table::Update ] | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbm, $result) = @_;

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @ids;
    foreach my $query ( @$queries ) {

        my $sql  = $query->to_sql;
        my @bind = $query->to_bind;

        my $dbh = $dbm->rw( $query->table->schema );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        my $last_insert_id = $query->has_insert_id
            ? $query->insert_id
            : $dbh->last_insert_id( undef, undef, undef, undef, {} );

        push @ids => $last_insert_id;
    }

    my $hash = { ids => \@ids };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
