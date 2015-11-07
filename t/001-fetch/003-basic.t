#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Action::DBH::Manager');

    use_ok('SQL::Action::Table');

    use_ok('SQL::Action::Fetch::One');
    use_ok('SQL::Action::Fetch::Many');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $dbm = SQL::Action::DBH::Manager->new(
        schemas => { __DEFAULT__ => { rw => $DBH } }
    );
    isa_ok($dbm, 'SQL::Action::DBH::Manager');

    my $Person = SQL::Action::Table->new(
        name   => 'person',
        driver => $DRIVER,
    );

    my $Comment = SQL::Action::Table->new(
        name   => 'comment',
        driver => $DRIVER,
    );

    my $Article = SQL::Action::Table->new(
        name   => 'article',
        driver => $DRIVER,
    );

    my $Article2Person = SQL::Action::Table->new(
        name   => 'xref_article_author',
        driver => $DRIVER,
    );

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Action::Fetch::One->new(
            query => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );

        # NOTE:
        # so here we need to fetch the author relation
        # before we can fetch the actual person objects
        # so we start with the subquery to the xref table
        # and then query the person for each row (see below)
        my $authors_query = SQL::Action::Fetch::Many->new(
            query => $Article2Person->select(
                columns => [qw[ author ]],
                where   => [ article => $ARTICLE_ID ],
            ),
            # in the end we need to drop our
            # results in favor of the ones we
            # fetched in our subquery ...
            inflator => sub {
                my $rows = $_[0];
                return [ map { $_->{person} } @$rows ];
            }
        );

        # this is the person fetching part of above
        $authors_query->fetch_related(
            person => SQL::Action::Fetch::One->new(
                query => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{author} ]
                    );
                }
            )
        );

        $article_query->fetch_related( authors => $authors_query );

        $article_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        $article_query->fetch_related(
            approver => SQL::Action::Fetch::One->new(
                query => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                }
            )
        );

        my $article = $article_query->execute( $dbm, {} );

        #warn Dumper $article;

        is_deeply(
            $article,
            {
                id      => 1,
                title   => 'Title(1)',
                body    => 'Body(1)',
                status  => 'pending',
                created => $article->{created},
                updated => $article->{updated},
                comments => [
                    { id => 1, body => 'Yo!' },
                    { id => 2, body => 'Hey!' }
                ],
                approver => {
                    id   => 1,
                    name => 'Bob',
                    age  => 30
                },
                authors => [
                    {
                        id   => 1,
                        name => 'Bob',
                        age  => 30
                    },
                    {
                        id   => 2,
                        name => 'Alice',
                        age  => 32
                    }
                ]
            },
            '... got the uninflated stuff as expected'
        );

    };
}

done_testing;
