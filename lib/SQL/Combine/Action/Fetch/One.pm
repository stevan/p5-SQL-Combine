package SQL::Combine::Action::Fetch::One;
use Moose;

with 'SQL::Combine::Action::Fetch';

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->prepare_query( $result );
    my $sth   = $self->execute_query( $query  );
    my ($row) = $sth->fetchall_arrayref;

    # we return a scalar, always
    return undef unless @$row;

    my ($hash) = @{ $query->from_rows($row) };

    my $relations = $self->execute_relations( $hash );

    my $obj = $self->has_inflator
        ? $self->inflator->( $self->merge_results_and_relations( $hash, $relations ) )
        : $self->merge_results_and_relations( $hash, $relations );

    return $obj;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
