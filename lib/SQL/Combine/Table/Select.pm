package SQL::Combine::Table::Select;
use Moose;

use SQL::Composer::Select;

with 'SQL::Combine::Table::Query';

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
            driver     => $self->table->driver,
            from       => $self->table->name,
            join       => $params->{join},

            columns    => $params->{columns},

            where      => $params->{where},

            group_by   => $params->{group_by},
            having     => $params->{having},
            order_by   => $params->{order_by},

            limit      => $params->{limit},
            offset     => $params->{offset},

            for_update => $params->{for_update},
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
