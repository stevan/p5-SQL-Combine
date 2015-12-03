package SQL::Combine::Action::Fetch::One::OrCreateOne;
use Moose;

extends 'SQL::Combine::Action::Fetch::One';

has 'or_create' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Action::Create::One',
    required => 1,
);

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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
