#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Combine::DBH::Manager');

    use_ok('SQL::Combine::Table');

    use_ok('SQL::Combine::Fetch::One');
    use_ok('SQL::Combine::Fetch::Many');
    use_ok('SQL::Combine::Fetch::Many::XRef');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $dbm = SQL::Combine::DBH::Manager->new(
        schemas => {
            __DEFAULT__ => { rw => $DBH },
        }
    );
    isa_ok($dbm, 'SQL::Combine::DBH::Manager');

    my $Person = SQL::Combine::Table->new(
        name   => 'person',
        driver => $DRIVER,
    );

    my $Comment = SQL::Combine::Table->new(
        name   => 'comment',
        driver => $DRIVER,
    );

    my $Article = SQL::Combine::Table->new(
        name   => 'article',
        driver => $DRIVER,
    );

    my $Article2Person = SQL::Combine::Table->new(
        name   => 'xref_article_author',
        driver => $DRIVER,
    );

    subtest '... get person with comments and approvals' => sub {

        my $PERSON_ID = 1;

        my $person_query = SQL::Combine::Fetch::One->new(
            query => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );
        isa_ok($person_query, 'SQL::Combine::Fetch::One');
        ok($person_query->is_static, '... the query is static');

        $person_query->fetch_related(
            comments => SQL::Combine::Fetch::Many->new(
                query => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        $person_query->fetch_related(
            approvals => SQL::Combine::Fetch::Many->new(
                query => $Article->select(
                    columns => [qw[ id title body created updated status ]],
                    where   => [ approver => $PERSON_ID ],
                )
            )
        );

        my $approvals = $person_query->relations->{approvals}->execute( $dbm, {} );
        my $comments = $person_query->relations->{comments}->execute( $dbm, {} );

        is_deeply(
            $approvals,
            [
                {
                    id      => 1,
                    title   => 'Title(1)',
                    body    => 'Body(1)',
                    status  => 'pending',
                    created => $approvals->[0]->{created},
                    updated => $approvals->[0]->{updated}
                },
                {
                    id      => 2,
                    title   => 'Title(2)',
                    body    => 'Body(2)',
                    status  => 'pending',
                    created => $approvals->[1]->{created},
                    updated => $approvals->[1]->{updated}
                },
            ],
            '... got the approval subquery as expected'
        );

        is_deeply(
            $comments,
            [
                { id => 1, body => 'Yo!' },
                { id => 3, body => 'Yo! (again)' },
            ],
            '... got the comments subquery as expected'
        );

    };

    subtest '... get article with comments and approver' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Fetch::One->new(
            query => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        $article_query->fetch_related(
            comments => SQL::Combine::Fetch::Many->new(
                query => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                )
            )
        );

        $article_query->fetch_related(
            approver => SQL::Combine::Fetch::One->new(
                query => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                }
            )
        );

        my $approver = $article_query->relations->{approver}->execute( $dbm, { approver => 1 } );
        my $comments = $article_query->relations->{comments}->execute( $dbm, {} );

        is_deeply(
            $approver,
            {
                id   => 1,
                name => 'Bob',
                age  => 30
            },
            '... got the approver expected'
        );

        is_deeply(
            $comments,
            [
                { id => 1, body => 'Yo!' },
                { id => 2, body => 'Hey!' }
            ],
            '... got the comments expected'
        );

    };

    subtest '... get article including an x-ref table' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Fetch::One->new(
            query => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            )
        );
        isa_ok($article_query, 'SQL::Combine::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        $article_query->fetch_related(
            authors => SQL::Combine::Fetch::Many::XRef->new(
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
            )
        );

        my $authors = $article_query->relations->{authors}->execute( $dbm, {} );

        #warn Dumper $article;

        is_deeply(
            $authors,
            [
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
            ],
            '... got the uninflated stuff as expected'
        );

    };

}


done_testing;
