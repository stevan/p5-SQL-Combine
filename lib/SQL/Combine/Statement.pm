package SQL::Combine::Statement;
use strict;
use warnings;

use Carp 'confess';

sub new {
    my ($class, %args) = @_;

    ($args{table_name})
        || confess 'You must supply a `table_name` parameter';
    ($args{driver})
        || confess 'You must supply a `driver` parameter';

    bless {
        driver     => $args{driver},
        table_name => $args{table_name},
    } => $class;
}

sub driver     { $_[0]->{driver}     }
sub table_name { $_[0]->{table_name} }

1;

__END__

=pod

=cut
