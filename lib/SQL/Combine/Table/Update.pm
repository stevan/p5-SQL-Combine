package SQL::Combine::Table::Update;
use Moose;

use Clone ();
use SQL::Composer::Update;

with 'SQL::Combine::Table::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Update',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]],
    lazy    => 1,
    default => sub {
        my $self = shift;
        SQL::Composer::Update->new(
            driver => $self->table->driver,
            table  => $self->table->name,

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

sub locate_id {
    my $self = shift;

    my $primary_key = $self->primary_key;

    my $values = $self->values || $self->set;
    my %values = ref $values eq 'HASH' ? %$values : @$values;
    if ( my $id = $values{ $primary_key } ) {
        return $id;
    }
    else {
        my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
        if ( my $id = $where{ $primary_key } ) {
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
