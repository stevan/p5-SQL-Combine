package SQL::Combine::Action;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

sub new {
    my ($class, %args) = @_;

    my $schema = $args{schema};

    (blessed $schema && $schema->isa('SQL::Combine::Schema'))
        || confess 'The `schema` parameter is required and must be an instance of `SQL::Combine::Schema`';

    bless {
        schema => $schema,
    } => $class;
}

sub execute;
sub is_static;

sub schema { $_[0]->{schema} }

sub execute_query {
    my ($self, $query) = @_;

    (blessed $query && $query->isa('SQL::Combine::Query'))
        || confess 'The `query` object must be an instance of `SQL::Combine::Query`';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_dbh_for_query( $query );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    return $sth;
}

1;

__END__

=pod

=cut
