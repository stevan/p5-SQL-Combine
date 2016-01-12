package SQL::Combine::Query;
use strict;
use warnings;

use SQL::Combine::Statement;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Statement')   }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Statement::HAS,
        table_name => sub { confess 'You must supply a `table_name` parameter' },
    )
}

sub table_name { $_[0]->{table_name} }

sub locate_id;

our $IS_ABSTRACT; BEGIN { $IS_ABSTRACT = 1 }

1;

__END__

=pod

=cut
