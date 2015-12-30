package SQL::Combine::Table;
use strict;
use warnings;

use mop::object;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Query::Select;
use SQL::Combine::Query::Update;
use SQL::Combine::Query::Upsert;
use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Delete;

our @ISA; BEGIN { @ISA = ('mop::object') }
our %HAS; BEGIN {
    %HAS = (
        name       => sub { confess 'You must supply a `name` parameter'   },
        driver     => sub { confess 'You must supply a `driver` parameter' },
        table_name => sub {},
        columns    => sub {},
        schema     => sub {},
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $columns = $args->{columns} ) {
        confess 'The `columns` parameter must be an ARRAY ref'
            unless ref $columns eq 'ARRAY';
    }

    if ( my $schema = $args->{schema} ) {
        confess 'The `schema` parameter must be an instance of `SQL::Combine::Schema`'
            unless blessed $schema
                && $schema->isa('SQL::Combine::Schema');
    }

    return $args;
}

sub name   { $_[0]->{name}   }
sub driver { $_[0]->{driver} }

sub table_name { $_[0]->{table_name} //= $_[0]->{name} }

sub columns     {    $_[0]->{columns} }
sub has_columns { !! $_[0]->{columns} }

sub schema     {    $_[0]->{schema} }
sub has_schema { !! $_[0]->{schema} }

sub associate_with_schema {
    my ($self, $schema) = @_;
    Scalar::Util::weaken( $schema );
    $self->{schema} = $schema;
    $self;
}

sub fully_qualify_column_name {
    my ($self, $column_name) = @_;
    # TODO: actually check if column name is valid ...
    return join '.' => ( $self->table_name, $column_name );
}

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
        driver     => $self->driver,
        table_name => $self->table_name,
        %args
    );
}

sub update {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Update->new(
        driver     => $self->driver,
        table_name => $self->table_name,
        %args
    );
}

sub upsert {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Upsert->new(
        driver     => $self->driver,
        table_name => $self->table_name,
        %args
    );
}

sub insert {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Insert->new(
        driver     => $self->driver,
        table_name => $self->table_name,
        %args
    );
}

sub delete :method {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Delete->new(
        driver     => $self->driver,
        table_name => $self->table_name,
        %args
    );
}

1;

__END__

=pod

=cut
