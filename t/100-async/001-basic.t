#!perl

use strict;
use warnings;

use Test::More;

use DBI;
use Data::Dumper;

package DBIx::Async::Future {
    use strict;
    use warnings;

    use IO::Select;

    sub new {
        my ($class, %args) = @_;
        bless {
            sth     => $args{sth},
            _socket => IO::Select->new( $args{sth}->{Database}->mysql_fd )
        } => $class;
    }

    sub get {
        my ($self, %opts) = @_;
        my @fhs = $self->{_socket}->can_read( $opts{timeout} // () );
        return $self->{sth} if scalar @fhs;
        return;
    }
}

package DBIx::Async::Query {
    use strict;
    use warnings;

    sub new {
        my ($class, %args) = @_;

        bless {
            dbh  => $args{dbh},
            sql  => $args{sql},
            attr => $args{attr},
            bind => $args{bing},
        } => $class;
    }

    sub execute {
        my ($self) = @_;

        my $sql  = $self->{sql};
        my $dbh  = $self->{dbh};
        my $attr = $self->{attr} // {};
        my @bind = $self->{bind} ? @{$self->{bind}} : ();

        $attr->{async} //= 1;

        my $sth = $dbh->prepare( $sql, $attr );
        $sth->execute( @bind );

        return DBIx::Async::Future->new( sth => $sth );
    }
}


my $dbh1 = DBI->connect('dbi:mysql:host=localhost', '', '', { RaiseError => 1, PrintError => 1 })
    or die 'Cannot connect to the DB because: ' . DBI->errstr;

my $dbh2 = DBI->connect('dbi:mysql:host=localhost', '', '', { RaiseError => 1, PrintError => 1 })
    or die 'Cannot connect to the DB because: ' . DBI->errstr;

my $dbh3 = DBI->connect('dbi:mysql:host=localhost', '', '', { RaiseError => 1, PrintError => 1 })
    or die 'Cannot connect to the DB because: ' . DBI->errstr;

my @queries = (
    DBIx::Async::Query->new( sql => 'SELECT SLEEP(3), 3', dbh => $dbh3 ),
    DBIx::Async::Query->new( sql => 'SELECT SLEEP(2), 2', dbh => $dbh2 ),
    DBIx::Async::Query->new( sql => 'SELECT SLEEP(1), 1', dbh => $dbh1 ),
);

my @futures = map { $_->execute } @queries;

while ( @futures ) {
    foreach my $i ( 0 .. $#futures ) {
        my $sth = $futures[ $i ]->get( timeout => 0.5 );
        next unless $sth;
        delete $futures[ $i ];
        warn Dumper $sth->fetchrow_arrayref;
    }
}

done_testing;



