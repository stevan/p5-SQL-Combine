package SQL::Action::Fetch::Many;
use Moose;

use SQL::Action::Types;

with 'SQL::Action::Fetch';

has 'composer' => (
    is       => 'ro',
    isa      => 'SQL::Composer::Select | CodeRef',
    required => 1,
);

has 'inflator' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_inflator'
);

has '_relations' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef[SQL::Action::Fetch]',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        fetch_related => 'set'
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

    my $rows = $sth->fetchall_arrayref;
    return unless @$rows;

    my $hashes = $composer->from_rows($rows);

    foreach my $hash ( @$hashes ) {
        foreach my $rel ( keys %{ $self->{_relations} } ) {
            $hash->{ $rel } = $self->{_relations}->{ $rel }->execute( $dbh, $attrs, $hash );
        }
    }

    my $objs = $self->has_inflator ? $self->inflator->( $hashes ) : $hashes;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
