package SQL::Combine::Action;
use Moose::Role;

use SQL::Combine::Schema;

has 'schema' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Schema',
    required => 1
);

requires 'execute';

requires 'is_static';

no Moose::Role; 1;

__END__

=pod

=cut
