package SQL::Combine::Action::Store::One;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action::Store',
           'SQL::Combine::Action::Role::WithRelations';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    if ( my $query = $args{query} ) {
        ((ref $query eq 'CODE') || (blessed $query && $query->isa('SQL::Combine::Query')))
            || confess 'The `query` parameter must be an instance of `SQL::Combine::Query` or a CODE ref which returns one';
        $self->{query} = $query;
    }
    else {
        confess 'The `query` parameter is required';
    }

    return $self;
}

sub query { $_[0]->{query} }

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

    my $sth  = $self->execute_query( $self->prepare_query( $result ) );
    my $hash = { rows => $sth->rows };
    my $rels = $self->execute_relations( $hash );

    return $self->merge_results_and_relations( $hash, $rels );
}

1;

__END__

=pod

=cut
