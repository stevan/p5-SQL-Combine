package SQL::Combine::Query::Select;
use Moose;

use Clone ();
use SQL::Composer::Select;

with 'SQL::Combine::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Select',
    handles => [qw[
        to_sql
        to_bind
    ]],
    lazy    => 1,
    default => sub {
        my $self = shift;
        SQL::Composer::Select->new(
            driver     => $self->driver,
            from       => $self->table_name,
            join       => Clone::clone($self->join),

            columns    => Clone::clone($self->columns),

            where      => Clone::clone($self->where),

            group_by   => Clone::clone($self->group_by),
            having     => Clone::clone($self->having),
            order_by   => Clone::clone($self->order_by),

            limit      => Clone::clone($self->limit),
            offset     => Clone::clone($self->offset),

            for_update => Clone::clone($self->for_update),
        )
    }
);

has join         => ( is => 'ro' );
has columns      => ( is => 'ro' );
has where        => ( is => 'ro' );

has group_by     => ( is => 'ro' );
has order_by     => ( is => 'ro' );
has having       => ( is => 'ro' );

has limit        => ( is => 'ro' );
has offset       => ( is => 'ro' );

has for_update   => ( is => 'ro' );

has row_inflator => ( is => 'ro', isa => 'CodeRef', predicate => 'has_row_inflator' );

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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
