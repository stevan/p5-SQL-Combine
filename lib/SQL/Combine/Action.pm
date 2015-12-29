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
        schema    => $schema,
        relations => +{},
    } => $class;
}

sub execute;
sub is_static;

sub schema { $_[0]->{schema} }

sub relations     {    $_[0]->{relations}   }
sub all_relations { %{ $_[0]->{relations} } }

sub relates_to {
    my ($self, $name, $action) = @_;
    (blessed $action && $action->isa('SQL::Combine::Action'))
        || confess 'The `action` being related must be an instance of `SQL::Combine::Action`';
    $self->{relations}->{ $name } = $action;
    $self;
}

sub execute_relations {
    my ($self, $hash, $attrs) = @_;
    my %results;
    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $results{ $rel } = $relations{ $rel }->execute( $hash, $attrs );
    }
    return \%results;
}

sub merge_results_and_relations {
    my ($self, $results, $relations) = @_;
    if ( ref $results eq 'HASH' &&  ref $relations eq 'HASH' ) {
        return { %$results, %$relations };
    }
    elsif ( ref $results eq 'ARRAY' &&  ref $relations eq 'HASH' ) {
        return { __RESULTS__ => $results, %$relations };
    }
    else {
        die "I have no idea what to do with $results and $relations";
    }
}

sub execute_query {
    my ($self, $query, $attrs) = @_;

    (blessed $query && $query->isa('SQL::Combine::Query'))
        || confess 'The `query` object must be an instance of `SQL::Combine::Query`';

    $attrs //= +{};

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_dbh_for_query( $query );
    my $sth = $dbh->prepare( $sql, $attrs );
    $sth->execute( @bind );

    return $sth;
}

1;

__END__

=pod

=cut
