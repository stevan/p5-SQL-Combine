package SQL::Combine::Query::Select::RawSQL;
use Moose;

with 'SQL::Combine::Query';

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
sub locate_id     { return } # XXX: not sure what we should do here - SL
# NOTE:
# So the locate_id method is actually
# the builder for the id attribute,
# which is a Maybe[Num], so we can
# simply return `undef` from this
# and but if we actually care, we
# should define `id` via the constructor
# - SL

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
