package SQL::Combine::Action::Fetch::One;
use strict;
use warnings;

use SQL::Combine::Action::Fetch;
use SQL::Combine::Action::Role::WithRelations;

our @ISA;  BEGIN { @ISA  = ('SQL::Combine::Action::Fetch') }
our @DOES; BEGIN { @DOES = ('SQL::Combine::Action::Role::WithRelations') }
our %HAS;  BEGIN { %HAS  = (%SQL::Combine::Action::Fetch::HAS) }

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->prepare_query( $result );
    my $dbh   = $self->schema->get_dbh_for_query( $query );
    my $sth   = $self->execute_query( $dbh, $query );
    my ($row) = $sth->fetchall_arrayref;

    # we return a scalar, always
    return undef unless @$row;

    my ($hash) = @{ $query->from_rows($row) };
    my $rels = $self->execute_relations( $hash );

    my $obj = $self->has_inflator
        ? $self->inflator->( $self->merge_results_and_relations( $hash, $rels ) )
        : $self->merge_results_and_relations( $hash, $rels );

    return $obj;
}

BEGIN {
    use mop;
    mop::internal::util::APPLY_ROLES(
        mop::role->new( name => __PACKAGE__ ),
        \@DOES,
        to => 'role'
    )
}

1;

__END__

=pod

=cut
