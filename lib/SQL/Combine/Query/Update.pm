package SQL::Combine::Query::Update;
use Moose;

use Clone ();
use SQL::Composer::Update;

with 'SQL::Combine::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Update',
    handles => [qw[
        to_sql
        to_bind
    ]],
    lazy    => 1,
    default => sub {
        my $self = shift;
        SQL::Composer::Update->new(
            driver => $self->driver,
            table  => $self->table_name,

            values => Clone::clone($self->values),
            set    => Clone::clone($self->set),

            where  => Clone::clone($self->where),

            limit  => Clone::clone($self->limit),
            offset => Clone::clone($self->offset),
        )
    }
);

has values => ( is => 'ro' );
has set    => ( is => 'ro' );

has where  => ( is => 'ro' );

has limit  => ( is => 'ro' );
has offset => ( is => 'ro' );

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;

    my $values = $self->values || $self->set;
    my %values = ref $values eq 'HASH' ? %$values : @$values;
    if ( my $id = $values{ $key } ) {
        return $id;
    }
    else {
        my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
        if ( my $id = $where{ $key } ) {
            return $id;
        }
    }
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
