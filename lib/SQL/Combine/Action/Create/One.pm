package SQL::Combine::Action::Create::One;
use Moose;

use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Upsert;

with 'SQL::Combine::Action::Create';

has 'query' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Query::Insert | SQL::Combine::Query::Upsert | SQL::Combine::Query::Update | CodeRef',
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

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_rw_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $last_insert_id = $query->id // $dbh->last_insert_id( undef, undef, undef, undef, {} );

    my $hash = { id => $last_insert_id };

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
