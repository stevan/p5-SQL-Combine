package SQL::Combine::Action::Fetch;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::HAS,
        inflator => sub {},
        query    => sub { confess 'The `query` parameter is required'  },
        schema   => sub { confess 'The `schema` parameter is required' },
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

    if ( my $inflator = $args->{inflator} ) {
        confess 'The `inflator` parameter must be a CODE ref'
            unless ref $inflator eq 'CODE';
    }

    return $args;
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
