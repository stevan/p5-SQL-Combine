package SQL::Combine::Schema::Manager;
use Moose;

use SQL::Combine::Schema;

has '_schema_map' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Schema]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'get_schema_by_name' => 'get',
        'get_schema_names'   => 'keys',
        'get_all_schemas'    => 'values',
    }
);

sub BUILD {
    my ($self, $params) = @_;

    confess "Invalid `schemas` key was passed"
        unless defined $params->{schemas}
            &&     ref $params->{schemas} eq 'ARRAY';

    my $map = $self->_schema_map;
    $map->{ $_->name } = $_ foreach @{ $params->{schemas} };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
