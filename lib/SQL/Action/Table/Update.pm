package SQL::Action::Table::Update;
use Moose;

use SQL::Composer::Update;

with 'SQL::Action::Table::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Update',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

sub BUILD {
    my ($self, $params) = @_;
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
