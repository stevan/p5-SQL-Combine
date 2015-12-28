package SQL::Combine::Table;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Query::Select;
use SQL::Combine::Query::Update;
use SQL::Combine::Query::Upsert;
use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Delete;

sub new {
    my ($class, %args) = @_;

    ($args{name})
        || confess 'You must supply a `name` parameter';
    ($args{driver})
        || confess 'You must supply a `driver` parameter';

    if ( exists $args{columns} ) {
        (ref $args{columns} eq 'ARRAY')
            || confess 'The `columns` parameter must be an ARRAY ref';
    }

    if ( exists $args{schema} ) {
        (blessed $args{schema} && $args{schema}->isa('SQL::Combine::Schema'))
            || confess 'The `schema` parameter must be an instance of `SQL::Combine::Schema`';
    }

    bless {
        name       => $args{name},
        driver     => $args{driver},
        table_name => $args{table_name},
        columns    => $args{columns},
        schema     => $args{schema},
    } => $class;
}

sub name   { $_[0]->{name}   }
sub driver { $_[0]->{driver} }

sub table_name { $_[0]->{table_name} //= $_[0]->{name} }

sub columns     {    $_[0]->{columns} }
sub has_columns { !! $_[0]->{columns} }

sub schema     {    $_[0]->{schema} }
sub has_schema { !! $_[0]->{schema} }

sub _associate_with_schema {
    my ($self, $schema) = @_;
    Scalar::Util::weaken( $schema );
    $self->{schema} = $schema;
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
