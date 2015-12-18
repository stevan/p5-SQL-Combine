package SQL::Combine::Query::Delete;
use Moose;

use Clone ();
use SQL::Composer::Delete;

with 'SQL::Combine::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Delete',
    handles => [qw[
        to_sql
        to_bind
    ]],
    lazy    => 1,
    default => sub {
        my $self = shift;
        SQL::Composer::Delete->new(
            driver => $self->driver,
            from   => $self->table_name,

            where  => Clone::clone($self->where),

            limit  => Clone::clone($self->limit),
            offset => Clone::clone($self->offset),
        )
    }
);

has where  => ( is => 'ro' );
has limit  => ( is => 'ro' );
has offset => ( is => 'ro' );

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
    if ( my $id = $where{ $key } ) {
        return $id;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
