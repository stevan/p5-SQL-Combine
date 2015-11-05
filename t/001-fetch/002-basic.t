#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Composer::Select');

    use_ok('SQL::Action::DBH::Manager');

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

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Action::Fetch::One->new(
            query => SQL::Composer::Select->new(
                from    => 'article',
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );

        $article_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => SQL::Composer::Select->new(
                    from    => 'comment',
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        $article_query->fetch_related(
            approver => SQL::Action::Fetch::One->new(
                query => sub {
                    my $result = $_[0];
                    SQL::Composer::Select->new(
                        from    => 'person',
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                }
            )
        );

        my $article = $article_query->execute( $dbm, {} );

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

        my $article_query = SQL::Action::Fetch::One->new(
            query => SQL::Composer::Select->new(
                from    => 'article',
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );

        my $approver_query = SQL::Action::Fetch::One->new(
            query => sub {
                my $result = $_[0];
                SQL::Composer::Select->new(
                    from    => 'person',
                    columns => [qw[ id name age ]],
                    where   => [ id => $result->{approver} ],
                )
            }
        );

        $approver_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => sub {
                    my $result = $_[0];
                    SQL::Composer::Select->new(
                        from    => 'comment',
                        columns => [qw[ id ]],
                        where   => [ author => $result->{id}, article => $ARTICLE_ID ],
                    )
                }
            )
        );

        # NOTE:
        # This overrides the approver (id)
        # in the original result set
        # - SL
        $article_query->fetch_related( approver => $approver_query );

        $article_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => SQL::Composer::Select->new(
                    from    => 'comment',
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        my $article = $article_query->execute( $dbm, {} );

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

        my $article_query = SQL::Action::Fetch::One->new(
            query => SQL::Composer::Select->new(
                from    => 'article',
                columns => [qw[ id title body created updated status ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );

        my $comments_query = SQL::Action::Fetch::Many->new(
            query => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body author ]],
                where   => [ article => $ARTICLE_ID ],
            )
        );

        # NOTE:
        # This overrides the author (id)
        # in the original result set
        # - SL
        $comments_query->fetch_related(
            author => SQL::Action::Fetch::One->new(
                query => sub {
                    my $result = $_[0];
                    SQL::Composer::Select->new(
                        from    => 'person',
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{author} ],
                    )
                }
            )
        );

        $article_query->fetch_related( comments => $comments_query );

        my $article = $article_query->execute( $dbm, {} );

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
