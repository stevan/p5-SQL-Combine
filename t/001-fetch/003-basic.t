#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Combine::Schema');
    use_ok('SQL::Combine::Table');

    use_ok('SQL::Combine::Action::Fetch::One');
    use_ok('SQL::Combine::Action::Fetch::Many');
    use_ok('SQL::Combine::Action::Fetch::Many::XRef');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $User = SQL::Combine::Schema->new(
        name   => 'user',
        dbh    => { rw => $DBH },
        tables => [
            SQL::Combine::Table->new(
                name   => 'person',
                driver => $DRIVER,
            ),
            SQL::Combine::Table->new(
                name   => 'xref_article_author',
                driver => $DRIVER,
            ),
            SQL::Combine::Table->new(
                name   => 'comment',
                driver => $DRIVER,
            ),
            SQL::Combine::Table->new(
                name   => 'article',
                driver => $DRIVER,
            ),
        ]
    );

    my $Person         = $User->table('person');
    my $Comment        = $User->table('comment');
    my $Article        = $User->table('article');
    my $Article2Person = $User->table('xref_article_author');

    subtest '... get article including an x-ref table' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        # NOTE:
        # so here we need to fetch the author relation
        # before we can fetch the actual person objects
        # so we start with the subquery to the xref table
        # and then query the person for each row (see below)
        my $authors_query = SQL::Combine::Action::Fetch::Many->new(
            schema => $User,
            query  => $Article2Person->select(
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
            person => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{author} ]
                    );
                }
            )
        );
        isa_ok($authors_query, 'SQL::Combine::Action::Fetch::Many');
        ok($authors_query->is_static, '... the query is static');

        $article_query->fetch_related( authors => $authors_query );

        $article_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $User,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        $article_query->fetch_related(
            approver => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                }
            )
        );

        my $article = $article_query->execute;

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

    subtest '... get article including an x-ref table' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        my $authors_query = SQL::Combine::Action::Fetch::Many::XRef->new(
            schema     => $User,
            xref_query => $Article2Person->select(
                columns => [qw[ author ]],
                where   => [ article => $ARTICLE_ID ],
            ),
            query => sub {
                my $results = $_[0];
                $Person->select(
                    columns => [qw[ id name age ]],
                    where   => [ id => [ map { $_->{author} } @$results ] ]
                )
            }
        );
        isa_ok($authors_query, 'SQL::Combine::Action::Fetch::Many::XRef');
        ok(!$authors_query->is_static, '... the query is not static');

        $article_query->fetch_related( authors => $authors_query );

        $article_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $User,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        $article_query->fetch_related(
            approver => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                }
            )
        );

        my $article = $article_query->execute;

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
