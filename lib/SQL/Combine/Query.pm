package SQL::Combine::Query;
use strict;
use warnings;

use parent 'SQL::Combine::Statement';

sub locate_id;
sub is_idempotent;

sub to_sql;
sub to_bind;

1;

__END__

=pod

=cut
