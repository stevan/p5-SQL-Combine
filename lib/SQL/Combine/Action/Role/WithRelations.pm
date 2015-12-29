package SQL::Combine::Action::Role::WithRelations;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

sub relations     {    $_[0]->{relations} //= {}   }
sub all_relations { %{ $_[0]->{relations} //= {} } }

sub relates_to {
    my ($self, $name, $action) = @_;
    (blessed $action && $action->isa('SQL::Combine::Action'))
        || confess 'The `action` being related must be an instance of `SQL::Combine::Action`';
    $self->relations->{ $name } = $action;
    $self;
}

sub execute_relations {
    my ($self, $hash) = @_;
    my %results;
    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $results{ $rel } = $relations{ $rel }->execute( $hash );
    }
    return \%results;
}

sub merge_results_and_relations {
    my ($self, $results, $relations) = @_;
    if ( ref $results eq 'HASH' &&  ref $relations eq 'HASH' ) {
        return { %$results, %$relations };
    }
    elsif ( ref $results eq 'ARRAY' &&  ref $relations eq 'HASH' ) {
        return { __RESULTS__ => $results, %$relations };
    }
    else {
        confess "I have no idea what to do with $results and $relations";
    }
}

1;

__END__

=pod

=cut
