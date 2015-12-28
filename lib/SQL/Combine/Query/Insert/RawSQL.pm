package SQL::Combine::Query::Insert::RawSQL;
use strict;
use warnings;

use Carp 'confess';

use parent 'SQL::Combine::Query';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{id}  = $args{id};
    $self->{sql} = $args{sql} || confess 'You must supply a `sql` parameter';

    ($args{bind} && ref $args{bind} eq 'ARRAY')
        || confess 'The `bind` parameter is required and must be an ARRAY ref';

    $self->{bind} = $args{bind};

    if ( exists $args{row_inflator} ) {
        (ref $args{row_inflator} eq 'CODE')
            || confess 'The `row_inflator` parameter is required and must be a CODE ref';
        $self->{row_inflator} = $args{row_inflator};
    }

    return $self;
}

sub id     {    $_[0]->{id} }
sub has_id { !! $_[0]->{id} }

sub to_sql  {    $_[0]->{sql}    }
sub to_bind { @{ $_[0]->{bind} } }

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    return $self->id if $self->has_id;
    return;
}

1;

__END__

=pod

=cut
