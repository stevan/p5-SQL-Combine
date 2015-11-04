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
    my $objs   = $self->has_inflator ? $self->inflator->( $hashes ) : $hashes;

    return $objs;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
