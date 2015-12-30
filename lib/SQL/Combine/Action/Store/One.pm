package SQL::Combine::Action::Store::One;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action::Store;
use SQL::Combine::Action::Role::WithRelations;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action::Store', 'SQL::Combine::Action::Role::WithRelations') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::Store::HAS,
        %SQL::Combine::Action::Role::WithRelations::HAS,
        query  => sub { confess 'The `query` parameter is required' },
        schema => sub { confess 'The `schema` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $schema = $args->{schema} ) {
        confess 'The `schema` parameter is required and must be an instance of `SQL::Combine::Schema`'
            unless blessed $schema && $schema->isa('SQL::Combine::Schema');
    }

    if ( my $query = $args->{query} ) {
        confess 'The `query` parameter must be an instance of `SQL::Combine::Query` or a CODE ref which returns one'
            unless ref $query eq 'CODE'
                || blessed $query && $query->isa('SQL::Combine::Query');
    }

    return $args;
}

sub schema { $_[0]->{schema} }
sub query  { $_[0]->{query}  }

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE';
}

sub prepare_query {
    my ($self, $result) = @_;
    my $query = $self->query;
    $query = $query->( $result ) if ref $query eq 'CODE';
    return $query;
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->prepare_query( $result );
    my $dbh   = $self->schema->get_dbh_for_query( $query );

    my $sth  = $self->execute_query( $dbh, $query );
    my $hash = { rows => $sth->rows };
    my $rels = $self->execute_relations( $hash );

    return $self->merge_results_and_relations( $hash, $rels );
}

1;

__END__

=pod

=cut
