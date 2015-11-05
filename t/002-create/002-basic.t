#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Composer::Insert');
    use_ok('SQL::Composer::Upsert');
    use_ok('SQL::Composer::Select');

    use_ok('SQL::Action::DBH::Manager');

    use_ok('SQL::Action::Create::One');
    use_ok('SQL::Action::Create::Many');

    use_ok('SQL::Action::Fetch::One');
    use_ok('SQL::Action::Fetch::Many');
}

my $DBH        = Util::setup_dbh;
my $ARTICLE_ID = 1;

my $dbm = SQL::Action::DBH::Manager->new(
    schemas => {
        user     => { rw => $DBH },
        comments => { rw => $DBH },
        articles => { ro => $DBH },
    }
);
isa_ok($dbm, 'SQL::Action::DBH::Manager');

my $article_query = SQL::Action::Fetch::One->new(
    schema => 'articles',
    query  => SQL::Composer::Select->new(
        from    => 'article',
        columns => [qw[ id title body ]],
        where   => [ id => $ARTICLE_ID ]
    )
);
isa_ok($article_query, 'SQL::Action::Fetch::One');

$article_query->fetch_related(
    comments => SQL::Action::Fetch::Many->new(
        schema => 'comments',
        query  => SQL::Composer::Select->new(
            from     => 'comment',
            columns  => [qw[ id body author ]],
            where    => [ article => $ARTICLE_ID ],
        )
    )
);

subtest '... test some article stuff (before change)' => sub {
    my $article = $article_query->execute( $dbm, {} );

    is_deeply(
        $article,
        {
            id       => 1,
            title    => 'Title(1)',
            body     => 'Body(1)',
            comments => [
                { id => 1, author => 1, body => 'Yo!' },
                { id => 2, author => 2, body => 'Hey!' },
            ]
        },
        '... got the expected set of (changed) data'
    );
};

subtest '... simple insert with upsert' => sub {

    my $new_person_query = SQL::Action::Create::One->new(
        schema => 'user',
        query  => SQL::Composer::Insert->new(
            into   => 'person',
            values => [
                id   => 3,
                name => 'Jim',
                age  => 25
            ]
        )
    );

    $new_person_query->create_related(
        comments => SQL::Action::Create::Many->new(
            schema  => 'comments',
            queries => sub {
                my $result = $_[0];
                return [
                    SQL::Composer::Insert->new(
                        into   => 'comment',
                        values => [
                            id       => 5,
                            body     => 'Wassup!',
                            article  => $ARTICLE_ID,
                            author   => $result->{id}
                        ]
                    ),
                    SQL::Composer::Upsert->new(
                        into   => 'comment',
                        values => [
                            id       => 1,
                            body     => 'DOH!',
                            article  => $ARTICLE_ID,
                            author   => $result->{id}
                        ],
                        driver => 'SQLite'
                    ),
                ]
            }
        )
    );

    my $new_person_info = $new_person_query->execute( $dbm, {} );

    is_deeply(
        $new_person_info,
        { id => 3, comments => { ids => [ 5, 1 ] } },
        '... got the expected insert info'
    );

    my $person_query = SQL::Action::Fetch::One->new(
        schema => 'user',
        query  => SQL::Composer::Select->new(
            from    => 'person',
            columns => [qw[ id name age ]],
            where   => [ id => $new_person_info->{id} ]
        )
    );

    $person_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            schema => 'comments',
            query  => SQL::Composer::Select->new(
                from     => 'comment',
                columns  => [qw[ id body ]],
                where    => [ author => $new_person_info->{id} ],
                order_by => 'id'
            )
        )
    );

    my $jim = $person_query->execute( $dbm, {} );

    is_deeply(
        $jim,
        {
            id       => $new_person_info->{id},
            name     => 'Jim',
            age      => 25,
            comments => [
                {
                    id   => $new_person_info->{comments}->{ids}->[1],
                    body => 'DOH!'
                },
                {
                    id   => $new_person_info->{comments}->{ids}->[0],
                    body => 'Wassup!'
                },
            ]
        },
        '... got the selected data as expected'
    );

};

subtest '... test some article stuff (after change)' => sub {
    my $article = $article_query->execute( $dbm, {} );

    is_deeply(
        $article,
        {
            id       => 1,
            title    => 'Title(1)',
            body     => 'Body(1)',
            comments => [
                { id => 1, author => 3, body => 'DOH!' },
                { id => 2, author => 2, body => 'Hey!' },
                { id => 5, author => 3, body => 'Wassup!' },
            ]
        },
        '... got the expected set of (changed) data'
    );
};

done_testing;
