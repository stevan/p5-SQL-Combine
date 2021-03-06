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

    use_ok('SQL::Combine::Action::Create::One');
    use_ok('SQL::Combine::Action::Create::Many');

    use_ok('SQL::Combine::Action::Fetch::One');
    use_ok('SQL::Combine::Action::Fetch::Many');

    use_ok('SQL::Combine::Query::Insert::RawSQL');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $ARTICLE_ID = 1;

    my $User = SQL::Combine::Schema->new(
        name   => 'user',
        dbh    => { rw => $DBH },
        tables => [
            SQL::Combine::Table->new(
                name   => 'person',
                driver => $DRIVER,
            )
        ]
    );

    my $Other = SQL::Combine::Schema->new(
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
    );

    my $Person  = $User->table('person');
    my $Comment = $Other->table('comment');
    my $Article = $Other->table('article');

    my $article_query = SQL::Combine::Action::Fetch::One->new(
        schema => $Other,
        query  => $Article->select(
            columns => [qw[ id title body ]],
            where   => [ id => $ARTICLE_ID ],
        )
    );
    isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
    ok($article_query->is_static, '... the query is static');

    $article_query->relates_to(
        comments => SQL::Combine::Action::Fetch::Many->new(
            schema => $Other,
            query  => $Comment->select(
                columns  => [qw[ id body author ]],
                where    => [ article => $ARTICLE_ID ],
                order_by => 'id',
            )
        )
    );

    subtest '... test some article stuff (before change)' => sub {
        my $article = $article_query->execute;

        #warn Dumper $article;

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

        my $PERSON_ID = 3;

        my $new_person_query = SQL::Combine::Action::Create::One->new(
            schema => $User,
            query  => SQL::Combine::Query::Insert::RawSQL->new(
                id         => $PERSON_ID,
                sql        => 'INSERT INTO person (id, name, age) VALUES(?, ?, ?)',
                bind       => [ $PERSON_ID, 'Jim', 25 ],
                table_name => 'person',
                driver     => $DRIVER,
            )
        );
        isa_ok($new_person_query, 'SQL::Combine::Action::Create::One');
        ok($new_person_query->is_static, '... the query is static');

        $new_person_query->relates_to(
            comments => SQL::Combine::Action::Create::Many->new(
                schema  => $Other,
                queries => [
                    SQL::Combine::Query::Insert::RawSQL->new(
                        id         => 5,
                        sql        => 'INSERT INTO comment (id, body, article, author) VALUES(?, ?, ?, ?)',
                        bind       => [ 5, 'Wassup!', $ARTICLE_ID, $PERSON_ID ],
                        table_name => 'article',
                        driver     => $DRIVER,
                    ),
                    $Comment->update(
                        values => [
                            body   => 'DOH!',
                            author => $PERSON_ID
                        ],
                        where => [
                            id      => 1,
                            article => $ARTICLE_ID
                        ]
                    )
                ]
            )
        );

        my $new_person_info = $new_person_query->execute;

        #warn Dumper $new_person_info;

        is_deeply(
            $new_person_info,
            {
                id       => $PERSON_ID,
                comments => {
                    ids => [ 5, 1 ]
                }
            },
            '... got the expected insert info'
        );

        my $person_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );
        isa_ok($person_query, 'SQL::Combine::Action::Fetch::One');
        ok($person_query->is_static, '... the query is static');

        $person_query->relates_to(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => $Comment->select(
                    columns  => [qw[ id body ]],
                    where    => [ author => $PERSON_ID ],
                    order_by => 'id',
                )
            )
        );

        my $jim = $person_query->execute;

        #warn Dumper $jim;

        is_deeply(
            $jim,
            {
                id       => $PERSON_ID,
                name     => 'Jim',
                age      => 25,
                comments => [
                    {
                        id   => 1,
                        body => 'DOH!'
                    },
                    {
                        id   => 5,
                        body => 'Wassup!'
                    },
                ]
            },
            '... got the selected data as expected'
        );

    };

    subtest '... test some article stuff (after change)' => sub {
        my $article = $article_query->execute;

        #warn Dumper $article;

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
}

done_testing;
