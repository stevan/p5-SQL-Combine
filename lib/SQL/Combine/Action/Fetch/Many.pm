package SQL::Combine::Action::Fetch::Many;
use strict;
use warnings;

use parent 'SQL::Combine::Action::Fetch';

sub execute {
    my $self   = shift;
    my $result = shift // {};
    my $attrs  = shift // {};

    my $query = $self->prepare_query( $result );
    my $sth   = $self->execute_query( $query, $attrs );
    my @rows  = $sth->fetchall_arrayref;

    return unless @rows;

    my $hashes = $query->from_rows(@rows);

    my @merged;
    foreach my $hash ( @$hashes ) {
        my $rels = $self->execute_relations( $hash, $attrs );
        push @merged => $self->merge_results_and_relations( $hash, $rels );
    }

    my $objs = $self->has_inflator ? $self->inflator->( \@merged ) : \@merged;

    return $objs;
}

1;

__END__

=pod

=cut
