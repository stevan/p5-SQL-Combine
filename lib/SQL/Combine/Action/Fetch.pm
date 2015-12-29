package SQL::Combine::Action::Fetch;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    my $schema = $args{schema};
    (blessed $schema && $schema->isa('SQL::Combine::Schema'))
        || confess 'The `schema` parameter is required and must be an instance of `SQL::Combine::Schema`';
    $self->{schema} = $schema;

    if ( my $query = $args{query} ) {
        ((ref $query eq 'CODE') || (blessed $query && $query->isa('SQL::Combine::Query')))
            || confess 'The `query` parameter must be an instance of `SQL::Combine::Query` or a CODE ref which returns one';
        $self->{query} = $query;
    }
    else {
        confess 'The `query` parameter is required';
    }

    if ( my $inflator = $args{inflator} ) {
        (ref $inflator eq 'CODE')
            || confess 'The `inflator` parameter must be a CODE ref';
        $self->{inflator} = $inflator;
    }

    return $self;
}

sub schema { $_[0]->{schema} }
sub query  { $_[0]->{query}  }

sub inflator     {    $_[0]->{inflator} }
sub has_inflator { !! $_[0]->{inflator} }

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE'
}

sub prepare_query {
    my ($self, $result) = @_;
    my $query = $self->query;
    $query = $query->( $result ) if ref $query eq 'CODE';
    return $query;
}

1;

__END__

=pod

=cut
