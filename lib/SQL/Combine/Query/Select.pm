package SQL::Combine::Query::Select;
use strict;
use warnings;

use Carp  'confess';
use Clone ();
use SQL::Composer::Select;

use SQL::Combine::Query;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Query') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Query::HAS,
        columns      => sub { confess 'The `columns` parameter is required' },
        join         => sub {},
        where        => sub {},
        group_by     => sub {},
        order_by     => sub {},
        having       => sub {},
        limit        => sub {},
        offset       => sub {},
        for_update   => sub {},
        row_inflator => sub {},
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $row_inflator = $args->{row_inflator} ) {
        confess 'The `row_inflator` parameter must be a CODE ref'
            unless ref $row_inflator eq 'CODE';
    }

    return $args;
}

sub to_sql  { $_[0]->_composer->to_sql  }
sub to_bind { $_[0]->_composer->to_bind }

sub _composer {
    my ($self) = @_;
    $self->{_composer} //= SQL::Composer::Select->new(
        driver     => $self->driver,
        from       => $self->table_name,
        join       => Clone::clone($self->{join}),

        columns    => Clone::clone($self->{columns}),

        where      => Clone::clone($self->{where}),

        group_by   => Clone::clone($self->{group_by}),
        having     => Clone::clone($self->{having}),
        order_by   => Clone::clone($self->{order_by}),

        limit      => Clone::clone($self->{limit}),
        offset     => Clone::clone($self->{offset}),

        for_update => Clone::clone($self->{for_update}),
    );
}

sub join       { $_[0]->{join}    }
sub columns    { $_[0]->{columns} }
sub where      { $_[0]->{where}   }

sub group_by   { $_[0]->{group_by} }
sub order_by   { $_[0]->{order_by} }
sub having     { $_[0]->{having}   }

sub limit      { $_[0]->{limit}  }
sub offset     { $_[0]->{offset} }

sub for_update { $_[0]->{for_update} }

sub row_inflator     {    $_[0]->{row_inflator} }
sub has_row_inflator { !! $_[0]->{row_inflator} }

sub from_rows {
    my ($self, @rows) = @_;
    if ( $self->has_row_inflator ) {
        my @results;
        foreach my $row ( @rows ) {
            push @results => $self->row_inflator( $row );
        }
        return \@results;
    }
    else {
        $self->_composer->from_rows( @rows )
    }
}

sub is_idempotent { 1 }

sub locate_id {
    my ($self, $key) = @_;
    my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
    if ( my $id = $where{ $key } ) {
        return $id;
    }
    return;
}

1;

__END__

=pod

=cut
