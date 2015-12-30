package SQL::Combine::Statement;
use strict;
use warnings;

use mop::object;

use Carp 'confess';

our @ISA; BEGIN { @ISA = ('mop::object') }
our %HAS; BEGIN {
    %HAS = (
        table_name => sub { confess 'You must supply a `table_name` parameter' },
        driver     => sub { confess 'You must supply a `driver` parameter'     },
    )
}

sub driver     { $_[0]->{driver}     }
sub table_name { $_[0]->{table_name} }

1;

__END__

=pod

=cut
