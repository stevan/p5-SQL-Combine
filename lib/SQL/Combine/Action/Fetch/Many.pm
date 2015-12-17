package SQL::Combine::Action::Fetch::Many;
use Moose;

with 'SQL::Combine::Action::Fetch';

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->prepare_query( $result );
    my $sth   = $self->execute_query( $query  );
    my @rows  = $sth->fetchall_arrayref;

    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my @merged;
    foreach my $hash ( @$hashes ) {
        my $relations = $self->execute_relations( $hash );
        push @merged => { %$hash, %$relations };
    }

    my $objs = $self->has_inflator ? $self->inflator->( \@merged ) : \@merged;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
