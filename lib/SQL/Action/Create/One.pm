package SQL::Action::Create::One;
use Moose;

use SQL::Action::Types;

with 'SQL::Action::Create';

has 'composer' => (
    is       => 'ro',
    isa      => 'SQL::Composer::Insert | CodeRef',
    required => 1,
);

has '_relations' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef[SQL::Action::Create]',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        create_related => 'set'
    }
);

sub execute {
    my ($self, $dbh, $attrs, $result) = @_;

    my $composer = $self->composer;
    $composer = $composer->( $result )
        if ref $composer eq 'CODE';

    my $sql  = $composer->to_sql;
    my @bind = $composer->to_bind;

    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    my $hash = { id => $dbh->last_insert_id( undef, undef, undef, undef, {} ) };

    foreach my $rel ( keys %{ $self->{_relations} } ) {
        $hash->{ $rel } = $self->{_relations}->{ $rel }->execute( $dbh, $attrs, $hash );
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
