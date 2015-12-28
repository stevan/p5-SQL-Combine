package SQL::Combine::Schema;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Table;

sub new {
    my ($class, %args) = @_;

    ($args{dbh} && ref $args{dbh} eq 'HASH')
        || confess 'The `dbh` parameter is required and must be a HASH ref';

    ($args{tables} && ref $args{tables} eq 'ARRAY')
        || confess 'The `tables` parameter is required and must be an ARRAY ref';

    my %_table_map;
    foreach my $table ( @{ $args{tables} } ) {
        (blessed $table && $table->isa('SQL::Combine::Table'))
            || confess 'The `tables` parameter must contain only intances of `SQL::Combine::Table`';
        $_table_map{ $table->name } = $table;
    }

    my $self = bless {
        name       => $args{name},
        dbh        => $args{dbh},
        tables     => $args{tables},
        # private ...
        _table_map => \%_table_map,
    } => $class;

    foreach my $table ( @{ $self->{tables} } ) {
        $table->_associate_with_schema( $self );
    }

    return $self;
}

sub name   { $_[0]->{name}   }
sub dbh    { $_[0]->{dbh}    }
sub tables { $_[0]->{tables} }

sub table {
    my ($self, $name) = @_;
    return $self->{_table_map}->{ $name };
}

sub get_dbh_for_query {
    my ($self, $query) = @_;

    (blessed $query && $query->isa('SQL::Combine::Query'))
        || confess 'The `query` object must implement the SQL::Combine::Query role';

    return $query->is_idempotent ? $self->get_ro_dbh : $self->get_rw_dbh;
}

sub get_ro_dbh {
    my ($self) = @_;
    return $self->{dbh}->{ro}
        // $self->{dbh}->{rw}
        // confess 'Unable to find `ro` handle';
}

sub get_rw_dbh {
    my ($self) = @_;
    return $self->{dbh}->{rw}
        // confess 'Unable to find `rw` handle';
}

1;

__END__
