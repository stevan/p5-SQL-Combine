package SQL::Combine::Query::Select::RawSQL;
use Moose;

with 'SQL::Combine::Query';

has 'id' => ( is => 'ro', predicate => 'has_id' );

has 'sql' => (
    reader   => 'to_sql',
    isa      => 'Str',
    required => 1,
);

has 'bind' => (
    traits   => [ 'Array' ],
    is       => 'bare',
    isa      => 'ArrayRef',
    required => 1,
    handles  => { 'to_bind' => 'elements' }
);

has 'row_inflator' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => 1
);

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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
