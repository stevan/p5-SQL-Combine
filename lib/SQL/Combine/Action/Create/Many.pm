package SQL::Combine::Action::Create::Many;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use SQL::Combine::Action::Create;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Action::Create') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Action::Create::HAS,
        id_key  => sub { 'id' },
        queries => sub { confess 'The `queries` parameter is required' },
        schema  => sub { confess 'The `schema` parameter is required' },
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $schema = $args->{schema} ) {
        confess 'The `schema` parameter is required and must be an instance of `SQL::Combine::Schema`'
            unless blessed $schema && $schema->isa('SQL::Combine::Schema');
    }

    if ( my $queries = $args->{queries} ) {
        if ( ref $queries eq 'ARRAY' ) {
            (blessed $_ && $_->isa('SQL::Combine::Query'))
                || confess 'If the `queries` parameter is an ARRAY ref, it must containt instances of `SQL::Combine::Query` only'
                    foreach @$queries;
        }
        elsif ( ref $queries eq 'CODE' ) {
            # just checking
        }
        else {
            confess 'The `queries` parameter must be an ARRAY ref of instance of `SQL::Combine::Query` or a CODE ref which returns one';
        }
    }

    return $args;
}

sub schema  { $_[0]->{schema}  }
sub queries { $_[0]->{queries} }
sub id_key  { $_[0]->{id_key}  }

sub is_static {
    my $self = shift;
    return ref $self->queries ne 'CODE';
}

sub execute {
    my $self   = shift;
    my $result = shift // {};

    my $schema  = $self->schema;
    my $queries = $self->queries;
    $queries = $queries->( $result )
        if ref $queries eq 'CODE';

    my @ids;
    foreach my $query ( @$queries ) {
        my $dbh = $schema->get_dbh_for_query( $query );
        $self->execute_query( $dbh, $query );

        my $last_insert_id = $query->locate_id( $self->id_key )
            // $dbh->last_insert_id( undef, undef, undef, undef, {} );

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

1;

__END__

=pod

=cut
