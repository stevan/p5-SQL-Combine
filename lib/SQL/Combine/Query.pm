package SQL::Combine::Query;
use Moose::Role;

with 'SQL::Combine::Statement';

has 'primary_key' => ( is => 'ro', isa => 'Str', default => 'id' );

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
