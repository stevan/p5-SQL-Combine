package SQL::Combine::Schema;
use Moose;

use SQL::Combine::Table;

has 'name' => ( is => 'ro', isa => 'Str' );
has 'dbh'  => ( is => 'ro', isa => 'HashRef', required => 1 );

has '_table_map' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Table]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'table'    => 'get',
        'get_table_names' => 'keys',
        'get_all_tables'  => 'values',
    }
);

sub BUILD {
    my ($self, $params) = @_;

    confess "Invalid `tables` key was passed"
        unless defined $params->{tables}
            &&     ref $params->{tables} eq 'ARRAY';

    my $map = $self->_table_map;
    $map->{ $_->name } = $_ foreach @{ $params->{tables} };
    return;
}

sub get_ro_dbh {
    my ($self) = @_;
    return $self->dbh->{ro}
        // $self->dbh->{rw}
        // confess 'Unable to find `ro` handle';
}

sub get_rw_dbh {
    my ($self) = @_;
    return $self->dbh->{rw}
        // confess 'Unable to find `rw` handle';
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
