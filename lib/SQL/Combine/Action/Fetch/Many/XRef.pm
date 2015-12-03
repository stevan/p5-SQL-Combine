package SQL::Combine::Action::Fetch::Many::XRef;
use Moose;

with 'SQL::Combine::Action::Fetch';

has 'xref' => (
    is       => 'ro',
    does     => 'SQL::Combine::Action::Fetch',
    required => 1,
);

has '+query' => ( isa => 'CodeRef' );

sub is_static { return 0 }

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->query->( $self->xref->execute );
    my $sql   = $query->to_sql;
    my @bind  = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_ro_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my @rows = $sth->fetchall_arrayref;
    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my %relations = $self->all_relations;
    foreach my $hash ( @$hashes ) {
        foreach my $rel ( keys %relations ) {
            $hash->{ $rel } = $relations{ $rel }->execute( $hash );
        }
    }

    my $objs = $self->has_inflator ? $self->inflator->( $hashes ) : $hashes;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
