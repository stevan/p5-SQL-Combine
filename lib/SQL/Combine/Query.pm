package SQL::Combine::Query;
use Moose::Role;

has 'table_name'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'driver'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'primary_key' => ( is => 'ro', isa => 'Str', default => 'id' );

has 'id'   => (
    is        => 'ro',
    isa       => 'Maybe[Num]',
    writer    => 'set_id',
    lazy      => 1,
    builder   => 'locate_id'
);

requires 'locate_id';

# NOTE:
# from the SQL::Composer API and created
# as delegated methods, so can't easily
# check them in requires. *sigh*
# Moose!!!! </shakes-fist>
# - SL

# requires 'to_sql';
# requires 'to_bind';
# requires 'from_rows';

no Moose::Role; 1;

__END__

=pod

=cut
