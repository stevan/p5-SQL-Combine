package SQL::Combine::Query::Select::RawSQL;
use strict;
use warnings;

use Carp 'confess';

use SQL::Combine::Query;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Query') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Query::HAS,
        id           => sub {},
        sql          => sub { confess 'The `sql` parameter is required' },
        bind         => sub { confess 'The `bind` parameter is required' },
        row_inflator => sub {},
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->SUPER::BUILDARGS( @_ );

    if ( my $row_inflator = $args->{row_inflator} ) {
        confess 'The `row_inflator` parameter must be a CODE ref'
            unless ref $row_inflator eq 'CODE';
    }

    if ( my $bind = $args->{bind} ) {
        confess 'The `bind` parameter is required and must be an ARRAY ref'
            unless ref $bind eq 'ARRAY';
    }

    return $args;
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
