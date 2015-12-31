package SQL::Combine::Query;
use strict;
use warnings;

use SQL::Combine::Statement;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Statement')   }
our %HAS; BEGIN { %HAS = %SQL::Combine::Statement::HAS }

sub locate_id;
sub is_idempotent;

our $IS_ABSTRACT; BEGIN { $IS_ABSTRACT = 1 }

1;

__END__

=pod

=cut
