package SQL::Combine::Action::Fetch::One::OrCreateOne;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action::Fetch::One;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action::Fetch::One') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::Fetch::One::HAS,
        or_create => sub { confess 'The `or_create` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $or_create = $args->{or_create} ) {
        confess 'The `or_create` parameter is required and must be an instance of `SQL::Combine::Action::Create::One`'
            unless blessed $or_create && $or_create->isa('SQL::Combine::Action::Create::One');
    }

    return $args;
}

sub or_create { $_[0]->{or_create} }

sub is_static {
    my $self = shift;
    $self->or_create->is_static || $self->SUPER::is_static;
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $obj = $self->SUPER::execute( $result );
    return $obj if $obj;

    # NOTE:
    # We are going to ignore the return
    # value of create here since it is
    # just the IDs
    # - SL
    $self->or_create->execute( $result );
    return $self->SUPER::execute( $result );
}

1;

__END__

=pod

=cut
