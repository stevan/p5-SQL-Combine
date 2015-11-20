package SQL::Combine::Action::Store::Many;
use Moose;

use SQL::Combine::Query::Update;

with 'SQL::Combine::Action::Store';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Combine::Query::Update] | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @rows;
    foreach my $query ( @$queries ) {

        my $sql  = $query->to_sql;
        my @bind = $query->to_bind;

        my $dbh = $self->schema->get_rw_dbh;
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
