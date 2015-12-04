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

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Article->select(
                columns => [qw[ id title body created updated status approver ]],
                where   => [ id => $ARTICLE_ID ],
            ),
            inflator => sub {
                my $article = $_[0];

                return +{
                    type => 'article',
                    id   => $article->{id},
                    attributes => {
                        map {
                            $_ => $article->{ $_ }
                        } qw[ title body created updated status ]
                    },
                    relationships => {
                        comments => {
                            data => [
                                map +{
                                    type => $_->{type},
                                    id   => $_->{id}
                                }, @{ $article->{comments} }
                            ]
                        },
                        approver => {
                            data => { type => $article->{approver}->{type}, id => $article->{approver}->{id} }
                        }
                    },
                    included => [
                        $article->{approver},
                        @{ $article->{comments} },
                    ]
                }
            }
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        $article_query->relates_to(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $User,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                ),
                inflator => sub {
                    my $comments = $_[0];
                    return [
                        map +{
                            type => 'comment',
                            id   => $_->{id},
                            attributes => {
                                body => $_->{body}
                            }
                        }, @$comments
                    ]
                }
            )
        );

        $article_query->relates_to(
            approver => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    $Person->select(
                        columns => [qw[ id name age ]],
                        where   => [ id => $result->{approver} ],
                    )
                },
                inflator => sub {
                    my $approver = $_[0];
                    return +{
                        type => 'person',
                        id   => $approver->{id},
                        attributes => {
                            name => $approver->{name},
                            age  => $approver->{age},
                        }
                    }
                }
            )
        );

        my $article = $article_query->execute;

        is_deeply(
            $article,
            {
                type    => 'article',
                id      => 1,
                attributes => {
                    title   => 'Title(1)',
                    body    => 'Body(1)',
                    status  => 'pending',
                    created => $article->{attributes}->{created},
                    updated => $article->{attributes}->{updated},
                },
                relationships => {
                    comments => {
                        data => [
                            { type => 'comment', id => 1 },
                            { type => 'comment', id => 2 },
                        ]
                    },
                    approver => {
                        data => { type => 'person', id => 1 }
                    },
                },
                included => [
                    {
                        type => 'person',
                        id   => 1,
                        attributes => {
                            name => 'Bob',
                            age  => 30
                        }
                    },
                    {
                        type => 'comment',
                        id   => 1,
                        attributes => {
                            body => 'Yo!'
                        }
                    },
                    {
                        type => 'comment',
                        id   => 2,
                        attributes => {
                            body => 'Hey!'
                        }
                    },
                ]
            },
            '... got the transformed inflated stuff as expected'
        );

        my $comments = $article_query->relations->{comments}->execute;

        is_deeply(
            $comments,
            [
                {
                    type => 'comment',
                    id   => 1,
                    attributes => {
                        body => 'Yo!'
                    }
                },
                {
                    type => 'comment',
                    id   => 2,
                    attributes => {
                        body => 'Hey!'
                    }
                },
            ],
            '... got the transformed inflated subquery stuff as expected'
        );

        my $approver = $article_query->relations->{approver}->execute;

        is_deeply(
            $approver,
            {
                type => 'person',
                id   => 1,
                attributes => {
                    name => 'Bob',
                    age  => 30
                }
            },
            '... got the transformed inflated subquery stuff as expected'
        );


    };


}

done_testing;
