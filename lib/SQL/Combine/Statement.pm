package SQL::Combine::Statement;
use strict;
use warnings;

use mop::object;

use Carp 'confess';

our @ISA; BEGIN { @ISA = ('mop::object') }
our %HAS; BEGIN {
    %HAS = (
        driver => sub { confess 'You must supply a `driver` parameter' },
    )
}

sub driver { $_[0]->{driver} }

sub is_idempotent;

sub to_sql;
sub to_bind;

our $IS_ABSTRACT; BEGIN { $IS_ABSTRACT = 1 }

1;

__END__

=pod

=cut
