package SQL::Combine::Table::Update;
use Moose;

use SQL::Composer::Update;

with 'SQL::Combine::Table::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Update',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

has 'primary_key' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->table->primary_key }
);

has 'insert_id'   => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_insert_id',
    writer    => 'set_insert_id',
);

sub BUILD {
    my ($self, $params) = @_;

    my $primary_key = $self->primary_key;

    my $values = $params->{values} || $params->{set};
    my %values = ref $values eq 'HASH' ? %$values : @$values;
    if ( my $id = $values{ $primary_key } ) {
        $self->set_insert_id( $id );
    }
    else {
        my %where = ref $params->{where} eq 'HASH' ? %{ $params->{where} } : @{ $params->{where} };
        if ( my $id = $where{ $primary_key } ) {
            $self->set_insert_id( $id );
        }
    }

    $self->_composer(
        SQL::Composer::Update->new(
            driver => $self->table->driver,
            table  => $self->table->name,

            values => $params->{values},
            set    => $params->{set},

            where  => $params->{where},

            limit  => $params->{limit},
            offset => $params->{offset},
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
