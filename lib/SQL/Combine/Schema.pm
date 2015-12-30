package SQL::Combine::Schema;
use strict;
use warnings;

use mop::object;

use Carp         'confess';
use Scalar::Util 'blessed';

our @ISA; BEGIN { @ISA = ('mop::object') }
our %HAS; BEGIN {
    %HAS = (
        name       => sub {},
        tables     => sub {},
        dbh        => sub { confess 'The `dbh` parameter is required and must be a HASH ref' },
        _table_map => sub { +{} },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    confess 'The `tables` parameter is required and must be an ARRAY ref'
        unless ref $args->{tables} eq 'ARRAY';

    (blessed $_ && $_->isa('SQL::Combine::Table'))
        || confess 'The `tables` parameter must contain only intances of `SQL::Combine::Table`'
            foreach @{ $args->{tables} };

    return $args;
}

sub BUILD {
    my ($self) = @_;
    foreach my $table ( @{ $self->{tables} } ) {
        $table->associate_with_schema( $self );
        $self->{_table_map}->{ $table->name } = $table;
    }
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
