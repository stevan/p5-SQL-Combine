package SQL::Combine::Action::Store::Many;
use Moose;

use SQL::Combine::Query::Update;

with 'SQL::Combine::Action::Store';

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Combine::Query::Update] | CodeRef',
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

    my @rows;
    foreach my $query ( @$queries ) {
        my $sth = $self->execute_query( $query );
        push @rows => $sth->rows;
    }

    my $hash = { rows => \@rows };

    # TODO;
    # Think about relations here, are they sensible?
    # If they are not sensible then we have to think
    # about how to turn them off.
    # - SL

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
