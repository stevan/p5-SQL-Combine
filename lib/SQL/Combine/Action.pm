package SQL::Combine::Action;
use strict;
use warnings;

use mop::object;

use Carp         'confess';
use Scalar::Util 'blessed';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub execute;
sub is_static;

sub execute_query {
    my ($self, $dbh, $query) = @_;

    (blessed $dbh && $dbh->isa('DBI::db'))
        || confess 'The `dbh` object must be an instance of `DBI::db`';

    (blessed $query && $query->isa('SQL::Combine::Query'))
        || confess 'The `query` object must be an instance of `SQL::Combine::Query`';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR 'SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    return $sth;
}

our $IS_ABSTRACT; BEGIN { $IS_ABSTRACT = 1 }

1;

__END__

=pod

=cut
