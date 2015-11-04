package SQL::Action::Fetch::One;
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

    my ($hash) = @{ $composer->from_rows($rows) };

    foreach my $rel ( keys %{ $self->{_relations} } ) {
        $hash->{ $rel } = $self->{_relations}->{ $rel }->execute( $dbh, $attrs, $hash );
    }

    my $obj = $self->has_inflator ? $self->inflator->( $hash ) : $hash;

    return $obj;
}

__PACKAGE__->meta->make_immutable;

no Moose::Util::TypeConstraints;
no Moose; 1;

__END__

=pod

=cut
