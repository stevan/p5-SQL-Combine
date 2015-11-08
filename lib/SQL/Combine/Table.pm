package SQL::Combine::Table;
use Moose;

use SQL::Combine::Table::Select;
use SQL::Combine::Table::Update;
use SQL::Combine::Table::Upsert;
use SQL::Combine::Table::Insert;
use SQL::Combine::Table::Delete;

has 'schema'      => ( is => 'ro', isa => 'Str', default => '__DEFAULT__' );
has 'name'        => ( is => 'ro', isa => 'Str' );
has 'primary_key' => ( is => 'ro', isa => 'Str', default => 'id' );
has 'driver'      => ( is => 'ro', isa => 'Str' );

sub select {
    my ($self, %args) = @_;
    return SQL::Combine::Table::Select->new( table => $self, %args );
}

sub update {
    my ($self, %args) = @_;
    return SQL::Combine::Table::Update->new( table => $self, %args );
}

sub upsert {
    my ($self, %args) = @_;
    return SQL::Combine::Table::Upsert->new( table => $self, %args );
}

sub insert {
    my ($self, %args) = @_;
    return SQL::Combine::Table::Insert->new( table => $self, %args );
}

sub delete {
    my ($self, %args) = @_;
    return SQL::Combine::Table::Delete->new( table => $self, %args );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
