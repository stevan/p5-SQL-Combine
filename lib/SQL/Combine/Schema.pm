package SQL::Combine::Schema;
use Moose;

use SQL::Combine::Table;

has 'name' => ( is => 'ro', isa => 'Str' );
has 'dbh'  => ( is => 'ro', isa => 'HashRef', required => 1 );

has 'tables' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Combine::Table]',
    required => 1
);

has '_table_map' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Table]',
    handles  => { 'table' => 'get' },
    lazy     => 1,
    default  => sub {
        my $self = $_[0];
        my %map;
        foreach my $table ( @{ $self->tables } ) {
            $table->_associate_with_schema( $self );
            $map{ $table->name } = $table;
        }
        return \%map;
    }
);

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
