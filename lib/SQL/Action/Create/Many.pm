package SQL::Action::Create::Many;
use Moose;

use SQL::Action::Types;

with 'SQL::Action::Create';

has 'composer' => (
    is       => 'ro',
    isa      => 'ArrayRef[SQL::Composer::Insert] | CodeRef',
    required => 1,
);

sub execute {
    my ($self, $dbh, $attrs, $result) = @_;

    my $composers = $self->composer;
    $composers = $composers->( $result )
        if ref $composers eq 'CODE';

    my @ids;
    foreach my $composer ( @$composers ) {

        my $sql  = $composer->to_sql;
        my @bind = $composer->to_bind;

        my $sth = $dbh->prepare( $sql );
        $sth->execute( @bind );

        push @ids => $dbh->last_insert_id( undef, undef, undef, undef, {} );
    }

    my $hash = { ids => \@ids };

    return $hash;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
