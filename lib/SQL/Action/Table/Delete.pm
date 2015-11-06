package SQL::Action::Table::Delete;
use Moose;

use SQL::Composer::Delete;

with 'SQL::Action::Table::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Delete',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

sub BUILD {
    my ($self, $params) = @_;
    $self->_composer(
        SQL::Composer::Delete->new(
            driver => $self->table->driver,
            from   => $self->table->name,

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
