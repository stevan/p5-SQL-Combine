package SQL::Combine::Action::Fetch::Many::XRef;
use Moose;

extends 'SQL::Combine::Action::Fetch::Many';

has 'xref' => (
    is       => 'ro',
    does     => 'SQL::Combine::Action::Fetch',
    required => 1,
);

has '+query' => ( isa => 'CodeRef' );

sub is_static { return 0 }

sub prepare_query {
    my ($self, undef) = @_;
    return $self->query->( $self->xref->execute );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
