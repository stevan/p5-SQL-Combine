package SQL::Action::Table::Upsert;
use Moose;

use SQL::Composer::Upsert;

with 'SQL::Action::Table::Op';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Upsert',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

sub BUILD {
    my ($self, $params) = @_;
    $self->_composer(
        SQL::Composer::Upsert->new(
            %{$params},
            into   => $self->table->name,
            driver => $self->table->driver,
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
