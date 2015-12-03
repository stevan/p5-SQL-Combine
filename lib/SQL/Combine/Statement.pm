package SQL::Combine::Statement;
use Moose::Role;

has 'table_name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'driver'     => ( is => 'ro', isa => 'Str', required => 1 );

no Moose::Role; 1;

__END__

=pod

=cut
