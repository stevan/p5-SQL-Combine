package SQL::Combine::Action::Fetch::Many::XRef;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action::Fetch::Many;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action::Fetch::Many') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::Fetch::Many::HAS,
        xref => sub { confess 'The `xref` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $query = $args->{query} ) {
        confess 'The `query` parameter must be a CODE ref'
            unless ref $query eq 'CODE';
    }

    if ( my $xref = $args->{xref} ) {
        confess 'The `xref` parameter is required and must be an instance of `SQL::Combine::Action::Fetch`'
            unless blessed $xref && $xref->isa('SQL::Combine::Action::Fetch');
    }

    return $args;
}

sub xref { $_[0]->{xref} }

sub is_static { return 0 }

sub prepare_query {
    my ($self, $results) = @_;
    return $self->query->( $self->xref->execute( $results ) );
}

1;

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
