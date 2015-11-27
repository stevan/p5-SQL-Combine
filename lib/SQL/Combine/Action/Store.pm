package SQL::Combine::Action::Store;
use Moose::Role;

with 'SQL::Combine::Action';

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Action::Store]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        _add_relation => 'set',
        all_relations => 'elements'
    }
);

sub store_related {
    my ($self, $name, $action) = @_;
    $self->_add_relation( $name, $action );
    $self;
}

no Moose::Role; 1;

__END__

=pod

=cut
