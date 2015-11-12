package SQL::Combine::DBH::Manager;
use Moose;

has 'schemas' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub ro {
    my ($self, $table) = @_;
    my $map = $self->schemas->{ $table // '__DEFAULT__' }
            // $self->schemas->{__DEFAULT__}
            // confess 'Unable to find handle for `'.$table.'`';
    return $map->{ro}
            // $map->{rw}
            // confess 'Unable to find `ro` handle for `'.$table.'`';
}

sub rw {
    my ($self, $table) = @_;
    my $map = $self->schemas->{ $table // '__DEFAULT__' }
            // $self->schemas->{__DEFAULT__}
            // confess 'Unable to find handle for `'.$table.'`';
    return $map->{rw}
            // confess 'Unable to find `rw` handle for `'.$table.'`';
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
