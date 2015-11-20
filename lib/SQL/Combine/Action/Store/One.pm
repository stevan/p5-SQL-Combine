package SQL::Combine::Action::Store::One;
use Moose;

with 'SQL::Combine::Action::Store';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Query::Update | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->query;
    $query = $query->( $result )
        if ref $query eq 'CODE';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    my $dbh = $self->schema->get_rw_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $hash = { rows => $sth->rows };

    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $hash->{ $rel } = $relations{ $rel }->execute( $hash );
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
