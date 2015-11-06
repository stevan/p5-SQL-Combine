package SQL::Action::Create::Many;
use Moose;

use SQL::Action::Table::Insert;

with 'SQL::Action::Create';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Action::Table::Op] | CodeRef',
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

        my $last_insert_id = $dbh->last_insert_id( undef, undef, undef, undef, {} );

        # FIXME
        # This has a lot of problems:
        # 1) it uses the `columns` hash field from the SQL::Composer::Insert
        # 2) It assumes that the id column is `id` (should be customizable)
        # 3) We duplicate the same logic in SQL::Action::Create::One
        # 4) It does not behave the same for Upserts
        # - SL
        if ( !$last_insert_id ) {
            my $found;
            my $idx = 0;
            foreach my $column ( @{ $query->_composer->{columns} } ) {
                ($found++, last) if $column eq 'id';
                $idx++;
            }

            $last_insert_id = $bind[ $idx ] if $found;
        }

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
