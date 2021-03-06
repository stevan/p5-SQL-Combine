package SQL::Combine::Query::Insert;
use Moose;

use Clone ();
use SQL::Composer::Insert;

with 'SQL::Combine::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Insert',
    handles => [qw[
        to_sql
        to_bind
    ]],
    lazy    => 1,
    default => sub {
        my $self = shift;
        SQL::Composer::Insert->new(
            driver => $self->driver,
            into   => $self->table_name,

            values => Clone::clone($self->values),
        )
    }
);

has values => ( is => 'ro' );

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    my %values = ref $self->values eq 'HASH' ? %{ $self->values } : @{ $self->values };
    if ( my $id = $values{ $key } ) {
        return $id;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
