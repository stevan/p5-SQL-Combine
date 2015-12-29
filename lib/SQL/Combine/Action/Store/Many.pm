package SQL::Combine::Action::Store::Many;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action::Store';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    if ( my $queries = $args{queries} ) {
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
        $self->{queries} = $queries;
    }
    else {
        confess 'The `queries` parameter is required';
    }

    return $self;
}

sub queries { $_[0]->{queries} }

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};
    my $attrs  = shift // {};

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @rows;
    foreach my $query ( @$queries ) {
        my $sth = $self->execute_query( $query, $attrs );
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
