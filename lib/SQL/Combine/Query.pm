package SQL::Combine::Query;
use Moose::Role;

with 'SQL::Combine::Statement';

requires 'locate_id';
requires 'is_idempotent';

no Moose::Role; 1;

__END__

=pod

=cut
