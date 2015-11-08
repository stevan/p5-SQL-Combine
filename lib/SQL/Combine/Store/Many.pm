package SQL::Combine::Store::Many;
use Moose;

use SQL::Combine::Table::Update;

with 'SQL::Combine::Store';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Combine::Table::Update] | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    not( ref $self->queries eq 'CODE' )
}

sub execute {
    my ($self, $dbm, $result) = @_;

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @rows;
    foreach my $query ( @$queries ) {

        my $sql  = $query->to_sql;
        my @bind = $query->to_bind;

        my $dbh = $dbm->rw( $query->table->schema );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        push @rows => $sth->rows;
    }

    my $hash = { rows => \@rows };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
