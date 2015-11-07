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

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Action::Fetch::One->new(
            query => $Article->select(
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
                                map +{ type => $_->{type}, id => $_->{id} }, @{ $article->{comments} }
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

        $article_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ article => $ARTICLE_ID ],
                ),
                inflator => sub {
                    my $comments = $_[0];
                    return [
                        map {
                            +{
                                type => 'comment',
                                id   => $_->{id},
                                attributes => {
                                    body => $_->{body}
                                }
                            }
                        } @$comments
                    ]
                }
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

        my $article = $article_query->execute( $dbm, {} );

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

        my $comments = $article_query->relations->{comments}->execute( $dbm, {} );

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

        my $approver = $article_query->relations->{approver}->execute( $dbm, {} );

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
