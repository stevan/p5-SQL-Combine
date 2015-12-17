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

    foreach my $hash ( @$hashes ) {
        $self->execute_relations( $hash );
    }

    my $objs = $self->has_inflator ? $self->inflator->( $hashes ) : $hashes;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
