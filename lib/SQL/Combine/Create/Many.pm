package SQL::Combine::Create::Many;
use Moose;

use SQL::Combine::Table::Insert;
use SQL::Combine::Table::Upsert;
use SQL::Combine::Table::Update;

with 'SQL::Combine::Create';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[ SQL::Combine::Table::Insert | SQL::Combine::Table::Upsert | SQL::Combine::Table::Update ] | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

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

        my $last_insert_id = $query->id // $dbh->last_insert_id( undef, undef, undef, undef, {} );

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
