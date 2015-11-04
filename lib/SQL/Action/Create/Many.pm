package SQL::Action::Create::Many;
use Moose;

with 'SQL::Action::Create';

has 'composers' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Composer::Insert] | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbm, $result) = @_;

    my $composers = $self->composers;
    $composers = $composers->( $result )
        if ref $composers eq 'CODE';

    my @ids;
    foreach my $composer ( @$composers ) {

        my $sql  = $composer->to_sql;
        my @bind = $composer->to_bind;

        my $dbh = $dbm->rw( $self->schema );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        push @ids => $dbh->last_insert_id( undef, undef, undef, undef, {} );
    }

    my $hash = { ids => \@ids };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
