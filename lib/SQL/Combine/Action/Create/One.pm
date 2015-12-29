package SQL::Combine::Action::Create::One;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Action::Create',
           'SQL::Combine::Action::Role::WithRelations';;

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{id_key} = $args{id_key} // 'id';

    if ( my $query = $args{query} ) {
        ((ref $query eq 'CODE') || (blessed $query && $query->isa('SQL::Combine::Query')))
            || confess 'The `query` parameter must be an instance of `SQL::Combine::Query` or a CODE ref which returns one';
        $self->{query} = $query;
    }
    else {
        confess 'The `query` parameter is required';
    }

    return $self;
}

sub query  { $_[0]->{query}  }
sub id_key { $_[0]->{id_key} }

sub is_static {
    my $self = shift;
    return ref $self->query ne 'CODE';
}

sub prepare_query {
    my ($self, $result) = @_;
    my $query = $self->query;
    $query = $query->( $result ) if ref $query eq 'CODE';
    return $query;
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $query = $self->prepare_query( $result );
    my $sth   = $self->execute_query( $query );

    my $last_insert_id = $query->locate_id( $self->id_key )
        // $self->schema
                ->get_rw_dbh
                ->last_insert_id( undef, undef, undef, undef, {} );

    my $hash = { id => $last_insert_id };
    my $rels = $self->execute_relations( $hash );

    return $self->merge_results_and_relations( $hash, $rels );
}

1;

__END__

=pod

=cut
