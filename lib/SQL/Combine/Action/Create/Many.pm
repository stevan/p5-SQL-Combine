package SQL::Combine::Action::Create::Many;
use Moose;

use SQL::Combine::Query::Insert;
use SQL::Combine::Query::Upsert;
use SQL::Combine::Query::Update;

use SQL::Combine::Query::Insert::RawSQL;

with 'SQL::Combine::Action::Create';

has 'id_key' => ( is => 'ro', isa => 'Str', default => 'id' );

has 'queries' => (
    is       => 'ro',
    isa      => 'ArrayRef[' . (join ' | ' => qw[
                    SQL::Combine::Query::Insert
                    SQL::Combine::Query::Upsert
                    SQL::Combine::Query::Update
                    SQL::Combine::Query::Insert::RawSQL
                ]) . '] | CodeRef',
    required => 1,
);

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @ids;
    foreach my $query ( @$queries ) {
        $self->execute_query( $query );

        my $last_insert_id = $query->locate_id( $self->id_key )
            // $self->schema
                    ->get_rw_dbh
                    ->last_insert_id( undef, undef, undef, undef, {} );

        push @ids => $last_insert_id;
    }

    my $hash = { ids => \@ids };

    # TODO;
    # Think about relations here, are they sensible?
    # If they are not sensible then we have to think
    # about how to turn them off.
    # - SL

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
