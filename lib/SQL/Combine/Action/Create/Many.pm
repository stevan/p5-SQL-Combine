package SQL::Combine::Action::Create::Many;
use Moose;

use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Upsert;
use SQL::Combine::Query::Update;

with 'SQL::Combine::Action::Create';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[ SQL::Combine::Query::Insert | SQL::Combine::Query::Upsert | SQL::Combine::Query::Update ] | CodeRef',
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

    my @ids;
    foreach my $query ( @$queries ) {

        my $sql  = $query->to_sql;
        my @bind = $query->to_bind;

        $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
            && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

        my $dbh = $self->schema->get_rw_dbh;
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
