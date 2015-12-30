package SQL::Combine::Action::Store::Many;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action::Store;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action::Store') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::Store::HAS,
        queries => sub { confess 'The `queries` parameter is required' },
        schema  => sub { confess 'The `schema` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $schema = $args->{schema} ) {
        confess 'The `schema` parameter is required and must be an instance of `SQL::Combine::Schema`'
            unless blessed $schema && $schema->isa('SQL::Combine::Schema');
    }

    if ( my $queries = $args->{queries} ) {
        if ( ref $queries eq 'ARRAY' ) {
            (blessed $_ && $_->isa('SQL::Combine::Query'))
                || confess 'If the `queries` parameter is an ARRAY ref, it must containt instances of `SQL::Combine::Query` only'
                    foreach @$queries;
        }
        elsif ( ref $queries eq 'CODE' ) {
            # just checking
        }
        else {
            confess 'The `queries` parameter must be an ARRAY ref of instance of `SQL::Combine::Query` or a CODE ref which returns one';
        }
    }

    return $args;
}

sub schema  { $_[0]->{schema}  }
sub queries { $_[0]->{queries} }

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @rows;
    foreach my $query ( @$queries ) {
        my $dbh = $self->schema->get_dbh_for_query( $query );
        my $sth = $self->execute_query( $dbh, $query );
        push @rows => $sth->rows;
    }

    my $hash = { rows => \@rows };

    # TODO;
    # Think about relations here, are they sensible?
    # If they are not sensible then we have to think
    # about how to turn them off.
    # - SL

    return $hash;
}

1;

__END__

=pod

=cut
