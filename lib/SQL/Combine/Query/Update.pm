package SQL::Combine::Query::Update;
use strict;
use warnings;

use Clone ();

use SQL::Composer::Update;

use parent 'SQL::Combine::Query';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new( %args );

    $self->{values} = $args{values};
    $self->{set}    = $args{set};
    $self->{where}  = $args{where};
    $self->{limit}  = $args{limit};
    $self->{offset} = $args{offset};

    return $self;
}

sub to_sql  { $_[0]->_composer->to_sql  }
sub to_bind { $_[0]->_composer->to_bind }

sub _composer {
    my ($self) = @_;
    $self->{_composer} //= SQL::Composer::Update->new(
        driver => $self->driver,
        table  => $self->table_name,

        values => Clone::clone($self->{values}),
        set    => Clone::clone($self->{set}),

        where  => Clone::clone($self->{where}),

        limit  => Clone::clone($self->{limit}),
        offset => Clone::clone($self->{offset}),
    );
}


sub values { $_[0]->{values} }
sub set    { $_[0]->{set}    }

sub where  { $_[0]->{where}  }

sub limit  { $_[0]->{limit}  }
sub offset { $_[0]->{offset} }

sub is_idempotent { 0 }

sub locate_id {
    my ($self, $key) = @_;

    my $values = $self->values || $self->set;
    my %values = ref $values eq 'HASH' ? %$values : @$values;
    if ( my $id = $values{ $key } ) {
        return $id;
    }
    else {
        my %where = ref $self->where eq 'HASH' ? %{ $self->where } : @{ $self->where };
        if ( my $id = $where{ $key } ) {
            return $id;
        }
    }
    return;
}

1;

__END__

=pod

=cut
