package SQL::Action;
use Moose::Role;

has 'schema' => ( is => 'ro', isa => 'Str' );

requires 'execute';

no Moose::Role; 1;

__END__

=pod

=cut
