#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Combine::Schema::Manager');
    use_ok('SQL::Combine::Schema');
    use_ok('SQL::Combine::Table');

    use_ok('SQL::Combine::Action::Fetch::One');
    use_ok('SQL::Combine::Action::Fetch::Many');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $m = SQL::Combine::Schema::Manager->new(
        schemas => [
            SQL::Combine::Schema->new(
                name   => 'user',
                dbh    => { rw => $DBH },
                tables => [
                    SQL::Combine::Table->new(
                        name   => 'person',
                        driver => $DRIVER,
                    )
                ]
            ),
            SQL::Combine::Schema->new(
                name   => 'other',
                dbh    => { rw => $DBH },
                tables => [
                    SQL::Combine::Table->new(
                        name   => 'comment',
                        driver => $DRIVER,
                    ),
                    SQL::Combine::Table->new(
                        name   => 'article',
                        driver => $DRIVER,
                    )
                ]
            )
        ]
    );

    my $User  = $m->get_schema_by_name('user');
    my $Other = $m->get_schema_by_name('other');

    my $Person  = $User->get_table_by_name('person');
    my $Comment = $Other->get_table_by_name('comment');
    my $Article = $Other->get_table_by_name('article');

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $Other,
            query  => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        $article_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
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
                }
            },
            '... got the uninflated stuff as expected'
        );

    };

    subtest '... get article with approve & approver.comments' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $Other,
            query  => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        my $approver_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => sub {
                my $result = $_[0];
                $Person->select(
                    columns => [qw[ id name age ]],
                    where   => [ id => $result->{approver} ],
                )
            }
        );

        $approver_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => sub {
                    my $result = $_[0];
                    $Comment->select(
                        columns => [qw[ id ]],
                        where   => [ author => $result->{id}, article => $ARTICLE_ID ],
                    )
                }
            )
        );
        isa_ok($approver_query, 'SQL::Combine::Action::Fetch::One');
        ok(!$approver_query->is_static, '... the query is not static');

        # NOTE:
        # This overrides the approver (id)
        # in the original result set
        # - SL
        $article_query->fetch_related( approver => $approver_query );

        $article_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        my $article = $article_query->execute;

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
                    id       => 1,
                    name     => 'Bob',
                    age      => 30,
                    comments => [
                        { id => 1 }
                    ]
                }
            },
            '... got the uninflated stuff as expected'
        );

    };

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $Other,
            query  => $Article->select(
                columns => [qw[ id title body created updated status ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        my $comments_query = SQL::Combine::Action::Fetch::Many->new(
            schema => $Other,
            query  => $Comment->select(
                columns  => [qw[ id body author ]],
                where    => [ article => $ARTICLE_ID ],
                order_by => 'id'
            )
        );
        isa_ok($comments_query, 'SQL::Combine::Action::Fetch::Many');
        ok($comments_query->is_static, '... the query is static');

        # NOTE:
        # This overrides the author (id)
        # in the original result set
        # - SL
        $comments_query->fetch_related(
            author => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{author} ],
                    )
                }
            )
        );

        $article_query->fetch_related( comments => $comments_query );

        my $article = $article_query->execute;

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
                    {
                        id     => 1,
                        body   => 'Yo!',
                        author => {
                            id   => 1,
                            name => 'Bob',
                            age  => 30
                        }
                    },
                    {
                        id     => 2,
                        body   => 'Hey!',
                        author => {
                            id   => 2,
                            name => 'Alice',
                            age  => 32
                        }
                    }
                ],
            },
            '... got the uninflated stuff as expected'
        );

    };
}

done_testing;
