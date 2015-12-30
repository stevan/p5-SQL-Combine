package SQL::Combine::Query::Delete;
use strict;
use warnings;

use Clone ();
use SQL::Composer::Delete;

use SQL::Combine::Query;

our @ISA; BEGIN { @ISA = ('SQL::Combine::Query') }
our %HAS; BEGIN {
    %HAS = (
        %SQL::Combine::Query::HAS,
        where  => sub {},
        limit  => sub {},
        offset => sub {},
    )
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
