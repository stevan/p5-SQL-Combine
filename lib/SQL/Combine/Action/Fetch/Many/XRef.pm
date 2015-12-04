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
    my ($self, $results) = @_;
    return $self->query->( $self->xref->execute( $results ) );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 ATTRIBUTES

=head2 C<query>

This is inherited from the L<SQL::Combine::Action::Fetch> role
but here it is expected to always be a B<CodeRef>.

=head2 C<xref>

This is an object which does the L<SQL::Combine::Action::Fetch>
role, it is expected to return results in a form that matches
what the C<query> in expecting.

B<NOTE:> This attribute's type is L<SQL::Combine::Action::Fetch>
specifically to allow for it to be either a C<Fetch::One> or a
C<Fetch::Many> depending on what the C<query> is expecting. Since
both of these things are under the control of the user of this
class it makes sense to defer proper usage to them.

=cut
