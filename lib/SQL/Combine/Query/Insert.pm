package SQL::Combine::Query::Insert;
use strict;
use warnings;

use Clone ();

use SQL::Composer::Insert;

use parent 'SQL::Combine::Query';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{values} = $args{values};

    return $self;
}

sub to_sql  { $_[0]->_composer->to_sql  }
sub to_bind { $_[0]->_composer->to_bind }

sub _composer {
    my ($self) = @_;
    $self->{_composer} //= SQL::Composer::Insert->new(
        driver => $self->driver,
        into   => $self->table_name,

        values => Clone::clone($self->{values}),
    );
}

sub values { $_[0]->{values} }

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    my %values = ref $self->values eq 'HASH' ? %{ $self->values } : @{ $self->values };
    if ( my $id = $values{ $key } ) {
        return $id;
    }
    return;
}

1;

__END__

=pod

=cut
