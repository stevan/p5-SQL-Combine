package SQL::Combine;
use Moose::Role;

has 'schema' => ( is => 'ro', isa => 'Str' );

requires 'execute';

requires 'is_static';

no Moose::Role; 1;

__END__

=pod

=cut
