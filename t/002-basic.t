#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Composer::Select');

    use_ok('SQL::Action::Fetch::One');
    use_ok('SQL::Action::Fetch::Many');
}

my $DBH = Util::setup_dbh;

subtest '... get person with all relations (raw)' => sub {

    my $ARTICLE_ID = 1;

    my $article_query = SQL::Action::Fetch::One->new(
        composer => SQL::Composer::Select->new(
            from    => 'article',
            columns => [qw[ id title body created updated status approver ]],
            where   => [ id => $ARTICLE_ID ],
        )
    );

    $article_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body ]],
                where   => [ article => $ARTICLE_ID ],
            )
        )
    );

    $article_query->fetch_related(
        approver => SQL::Action::Fetch::One->new(
            composer => sub {
                my $result = $_[0];
                SQL::Composer::Select->new(
                    from    => 'person',
                    columns => [qw[ id name age ]],
                    where   => [ id => $result->{approver} ],
                )
            }
        )
    );

    my $article = $article_query->execute( $DBH, {} );

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

subtest '... get person with all relations (raw)' => sub {

    my $ARTICLE_ID = 1;

    my $article_query = SQL::Action::Fetch::One->new(
        composer => SQL::Composer::Select->new(
            from    => 'article',
            columns => [qw[ id title body created updated status approver ]],
            where   => [ id => $ARTICLE_ID ],
        )
    );

    my $approver_query = SQL::Action::Fetch::One->new(
        composer => sub {
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
            composer => sub {
                my $result = $_[0];
                SQL::Composer::Select->new(
                    from    => 'comment',
                    columns => [qw[ id body ]],
                    where   => [ author => $result->{id}, article => $ARTICLE_ID ],
                )
            }
        )
    );

    $article_query->fetch_related( approver => $approver_query );

    $article_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body ]],
                where   => [ article => $ARTICLE_ID ],
            )
        )
    );

    my $article = $article_query->execute( $DBH, {} );

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
                    { id => 1, body => 'Yo!' }
                ]
            }
        },
        '... got the uninflated stuff as expected'
    );

};


done_testing;
