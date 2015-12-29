package SQL::Combine::Action::Fetch::Many::XRef;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action::Fetch::Many';

sub new {
    my ($class, %args) = @_;

    (ref $args{query} eq 'CODE')
        || confess 'The `query` parameter must be a CODE ref';

    my $self = $class->SUPER::new( %args );

    my $xref = $args{xref};
    (blessed $xref && $xref->isa('SQL::Combine::Action::Fetch'))
        || confess 'The `xref` parameter is required and must be an instance of `SQL::Combine::Action::Fetch`';
    $self->{xref} = $xref;

    if ( my $xref_attrs = $args{xref_attrs} ) {
        (ref $xref_attrs eq 'HASH')
            || confess 'The `xref_attrs` parameter must be a HASH ref';
        $self->{xref_attrs} = $xref_attrs;
    }
    else {
        $self->{xref_attrs} = +{};
    }

    return $self;
}

sub xref       { $_[0]->{xref}       }
sub xref_attrs { $_[0]->{xref_attrs} }

sub is_static { return 0 }

sub prepare_query {
    my ($self, $results) = @_;
    return $self->query->( $self->xref->execute( $results, $self->xref_attrs ) );
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
