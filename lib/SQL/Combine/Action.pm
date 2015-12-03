package SQL::Combine::Action;
use Moose::Role;

use SQL::Combine::Schema;

has 'schema' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Schema',
    required => 1
);

requires 'execute';
requires 'is_static';

sub execute_query {
    my ($self, $query) = @_;

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_rw_dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    return $sth;
}

no Moose::Role; 1;

__END__

=pod

=cut
