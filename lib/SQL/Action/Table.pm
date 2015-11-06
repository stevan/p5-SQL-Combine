package SQL::Action::Table;
use Moose;

use SQL::Action::Table::Select;
use SQL::Action::Table::Update;
use SQL::Action::Table::Upsert;
use SQL::Action::Table::Insert;
use SQL::Action::Table::Delete;

has 'schema' => ( is => 'ro', isa => 'Str', default => '__DEFAULT__' );
has 'name'   => ( is => 'ro', isa => 'Str' );
has 'driver' => ( is => 'ro', isa => 'Str' );

sub select {
    my ($self, %args) = @_;
    return SQL::Action::Table::Select->new( table => $self, %args );
}

sub update {
    my ($self, %args) = @_;
    return SQL::Action::Table::Update->new( table => $self, %args );
}

sub upsert {
    my ($self, %args) = @_;
    return SQL::Action::Table::Upsert->new( table => $self, %args );
}

sub insert {
    my ($self, %args) = @_;
    return SQL::Action::Table::Insert->new( table => $self, %args );
}

sub delete {
    my ($self, %args) = @_;
    return SQL::Action::Table::Delete->new( table => $self, %args );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
