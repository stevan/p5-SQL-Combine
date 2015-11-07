package SQL::Combine::Table::Query;
use Moose::Role;

has 'table' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Table',
    required => 1,
);

no Moose::Role; 1;

__END__

=pod

=cut
