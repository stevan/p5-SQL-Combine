package SQL::Combine::Action::Fetch::Many;
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
    my @rows  = $sth->fetchall_arrayref;

    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my @merged;
    foreach my $hash ( @$hashes ) {
        my $rels = $self->execute_relations( $hash );
        push @merged => $self->merge_results_and_relations( $hash, $rels );
    }

    my $objs = $self->has_inflator ? $self->inflator->( \@merged ) : \@merged;

    return $objs;
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
