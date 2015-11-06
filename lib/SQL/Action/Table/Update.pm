package SQL::Action::Table::Update;
use Moose;

use SQL::Composer::Update;

with 'SQL::Action::Table::Op';

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
            %{$params},
            table  => $self->table->name,
            driver => $self->table->driver,
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
