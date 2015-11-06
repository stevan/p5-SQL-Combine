package SQL::Action::Table::Op;
use Moose::Role;

has 'table' => (
    is       => 'ro',
    isa      => 'SQL::Action::Table',
    required => 1,
);

no Moose::Role; 1;

__END__

=pod

=cut
