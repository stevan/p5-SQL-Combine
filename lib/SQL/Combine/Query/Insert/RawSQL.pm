package SQL::Combine::Query::Insert::RawSQL;
use Moose;

with 'SQL::Combine::Query';

has 'id' => ( is => 'ro', predicate => 'has_id' );

has 'sql' => (
    reader   => 'to_sql',
    isa      => 'Str',
    required => 1,
);

has 'bind' => (
    traits   => [ 'Array' ],
    is       => 'bare',
    isa      => 'ArrayRef',
    required => 1,
    handles  => { 'to_bind' => 'elements' }
);

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    return $self->id if $self->has_id;
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
