package SQL::Action::Table::Insert;
use Moose;

use SQL::Composer::Insert;

with 'SQL::Action::Table::Op';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Insert',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

sub BUILD {
    my ($self, $params) = @_;
    $self->_composer(
        SQL::Composer::Insert->new(
            driver => $self->table->driver,
            into   => $self->table->name,

            values => $params->{values},
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
