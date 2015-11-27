package SQL::Combine::Table;
use Moose;

use SQL::Combine::Query::Select;
use SQL::Combine::Query::Update;
use SQL::Combine::Query::Upsert;
use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Delete;

has 'name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'driver'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'primary_key' => ( is => 'ro', isa => 'Str', default => 'id' );
has 'columns'     => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_columns',
);

sub select :method {
    my ($self, %args) = @_;

    if ( $self->has_columns ) {
        $args{columns} = $self->columns
            if (not exists $args{columns})
            || (exists $args{columns}
                    && (not ref $args{columns})
                        && $args{columns} eq '*');
    }

    return SQL::Combine::Query::Select->new(
        driver      => $self->driver,
        table_name  => $self->name,
        primary_key => $self->primary_key,
        %args
    );
}

sub update {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Update->new(
        driver      => $self->driver,
        table_name  => $self->name,
        primary_key => $self->primary_key,
        %args
    );
}

sub upsert {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Upsert->new(
        driver      => $self->driver,
        table_name  => $self->name,
        primary_key => $self->primary_key,
        %args
    );
}

sub insert {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Insert->new(
        driver      => $self->driver,
        table_name  => $self->name,
        primary_key => $self->primary_key,
        %args
    );
}

sub delete :method {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Delete->new(
        driver      => $self->driver,
        table_name  => $self->name,
        primary_key => $self->primary_key,
        %args
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
