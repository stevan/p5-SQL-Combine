package SQL::Combine::Action::Fetch::One::OrCreateOne;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action::Fetch::One';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    my $or_create = $args{or_create};
    (blessed $or_create && $or_create->isa('SQL::Combine::Action::Create::One'))
        || confess 'The `or_create` parameter is required and must be an instance of `SQL::Combine::Action::Create::One`';
    $self->{or_create} = $or_create;

    return $self;
}

sub or_create { $_[0]->{or_create} }

sub is_static {
    my $self = shift;
    $self->or_create->is_static || $self->SUPER::is_static;
}

sub execute {
    my $self   = shift;
    my $result = shift // {};
    my $attrs  = shift // {};

    my $obj = $self->SUPER::execute( $result, $attrs );
    return $obj if $obj;

    # NOTE:
    # We are going to ignore the return
    # value of create here since it is
    # just the IDs
    # - SL
    $self->or_create->execute( $result, $attrs );
    return $self->SUPER::execute( $result, $attrs );
}

1;

__END__

=pod

=cut
