package SQL::Combine::Action::Sequence;
use Moose;

with 'SQL::Combine::Action';

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

has 'actions' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Combine::Action] | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    # if our actions is a CodeRef, we are not static
    return 0 if ref $self->actions eq 'CODE';
    # if we have actions, then we need to
    # check each one to see if it is static
    foreach my $action ( @{ $self->actions } ) {
        # if this is not static, then
        # it ruins it for all ...
        return 0 if not $action->is_static;
    }
    # if we get here, then
    # we are static
    return 1
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $actions = $self->actions;
    $actions = $actions->( $result )
        if ref $actions eq 'CODE';

    my @results;
    foreach my $action ( @$actions ) {
        my $x = $action->execute( $result );
        push @results => $x; # otherwise it doesn't push an undef on here
    }

    my $relations = $self->execute_relations( \@results );

    my $obj = $self->has_inflator
        ? $self->inflator->( $self->merge_results_and_relations( \@results, $relations ) )
        : $self->merge_results_and_relations( \@results, $relations );

    return $obj;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
