package SQL::Action::Table::Select;
use Moose;

use SQL::Composer::Select;

with 'SQL::Action::Table::Op';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Select',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

sub BUILD {
    my ($self, $params) = @_;
    $self->_composer(
        SQL::Composer::Select->new(
            %{$params},
            from   => $self->table->name,
            driver => $self->table->driver,
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
