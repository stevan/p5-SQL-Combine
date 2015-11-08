package SQL::Combine::Table::Query;
use Moose::Role;

has 'table' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Table',
    required => 1,
);

has 'primary_key' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->table->primary_key }
);

has 'id'   => (
    is        => 'ro',
    isa       => 'Maybe[Num]',
    writer    => 'set_id',
    lazy      => 1,
    builder   => 'locate_id'
);

requires 'locate_id';

no Moose::Role; 1;

__END__

=pod

=cut
