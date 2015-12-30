package SQL::Combine::Action::Store;
use strict;
use warnings;

use SQL::Combine::Action;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action') }
our %HAS; BEGIN { %HAS = %SQL::Combine::Action::HAS }

our $IS_ABSTRACT; BEGIN { $IS_ABSTRACT = 1 }

1;

__END__

=pod

=cut
