package SQL::Combine::Query::Delete;
use strict;
use warnings;

use Clone ();

use SQL::Composer::Delete;

use parent 'SQL::Combine::Query';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{where}  = $args{where};
    $self->{limit}  = $args{limit};
    $self->{offset} = $args{offset};

    return $self;
}

sub to_sql  { $_[0]->_composer->to_sql  }
sub to_bind { $_[0]->_composer->to_bind }

sub _composer {
    my ($self) = @_;
    $self->{_composer} //= SQL::Composer::Delete->new(
        driver => $self->driver,
        from   => $self->table_name,

        where  => Clone::clone($self->{where}),

        limit  => Clone::clone($self->{limit}),
        offset => Clone::clone($self->{offset}),
    );
}

sub where  { $_[0]->{where}  }
sub limit  { $_[0]->{limit}  }
sub offset { $_[0]->{offset} }

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;
    my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
    if ( my $id = $where{ $key } ) {
        return $id;
    }
    return;
}

1;

__END__

=pod

=cut
