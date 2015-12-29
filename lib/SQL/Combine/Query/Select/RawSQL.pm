package SQL::Combine::Query::Select::RawSQL;
use strict;
use warnings;

use Carp 'confess';

use parent 'SQL::Combine::Query';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{id}  = $args{id};
    $self->{sql} = $args{sql} || confess 'You must supply a `sql` parameter';

    my $bind = $args{bind};
    ($bind && ref $bind eq 'ARRAY')
        || confess 'The `bind` parameter is required and must be an ARRAY ref';
    $self->{bind} = $bind;

    if ( my $row_inflator = $args{row_inflator} ) {
        (ref $row_inflator eq 'CODE')
            || confess 'The `row_inflator` parameter is required and must be a CODE ref';
        $self->{row_inflator} = $row_inflator;
    }

    return $self;
}

sub id     {    $_[0]->{id} }
sub has_id { !! $_[0]->{id} }

sub to_sql  {    $_[0]->{sql}    }
sub to_bind { @{ $_[0]->{bind} } }

sub row_inflator     {    $_[0]->{row_inflator} }
sub has_row_inflator { !! $_[0]->{row_inflator} }

sub is_idempotent { 1 }

sub locate_id {
    my ($self, $key) = @_;
    return $self->id if $self->has_id;
    return;
}

sub from_rows {
    my ($self, @rows) = @_;
    my @result;
    foreach my $row ( @rows ) {
        foreach my $set ( @$row ) {
            push @result => $self->row_inflator->( $set );
        }
    }
    return \@result;
}

1;

__END__

=pod

=cut
