package SQL::Combine::Action::Sequence;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action;
use SQL::Combine::Action::Role::WithRelations;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action', 'SQL::Combine::Action::Role::WithRelations') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::HAS,
        %SQL::Combine::Action::Role::WithRelations::HAS,
        inflator => sub {},
        actions  => sub { confess 'The `actions` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $inflator = $args->{inflator} ) {
        confess 'The `inflator` parameter must be a CODE ref'
            unless ref $inflator eq 'CODE';
    }

    if ( my $actions = $args->{actions} ) {
        if ( ref $actions eq 'ARRAY' ) {
            (blessed $_ && $_->isa('SQL::Combine::Action'))
                || confess 'If the `actions` parameter is an ARRAY ref, it must containt instances of `SQL::Combine::Action` only'
                    foreach @$actions;
        }
        elsif ( ref $actions eq 'CODE' ) {
            # nothing ... just checking
        }
        else {
            confess 'The `actions` parameter must be either an ARRAY ref of `SQL::Combine::Action` instance, or a CODE ref which returns that';
        }
    }

    return $args;
}

sub inflator     {    $_[0]->{inflator} }
sub has_inflator { !! $_[0]->{inflator} }

sub actions { $_[0]->{actions} }

sub is_static {
    my $self = shift;
    # if our actions is a CodeRef, we are not static
    return 0 if ref $self->actions eq 'CODE';
    # if we have actions, then we need to
    # check each one to see if it is static
    foreach my $action ( @{ $self->actions } ) {
        # if this is not static, then
        # it ruins it for all ...
        return 0 if not $action->is_static;
    }
    # if we get here, then
    # we are static
    return 1
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $actions = $self->actions;
    $actions = $actions->( $result )
        if ref $actions eq 'CODE';

    my @results;
    foreach my $action ( @$actions ) {
        my $x = $action->execute( $result );
        push @results => $x; # otherwise it doesn't push an undef on here
    }

    my $rels = $self->execute_relations( \@results );

    my $obj = $self->has_inflator
        ? $self->inflator->( $self->merge_results_and_relations( \@results, $rels ) )
        : $self->merge_results_and_relations( \@results, $rels );

    return $obj;
}

1;

__END__

=pod

=cut
