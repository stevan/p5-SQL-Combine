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

    use_ok('SQL::Combine::Action::Create::One');
    use_ok('SQL::Combine::Action::Create::Many');

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
                    )
                ]
            )
        ]
    );
    isa_ok($m, 'SQL::Combine::Schema::Manager');

    my $User  = $m->get_schema_by_name('user');
    my $Other = $m->get_schema_by_name('other');

    my $Person  = $User->table('person');
    my $Comment = $Other->table('comment');

    subtest '... simple insert' => sub {

        my $PERSON_ID = 3;

        my $new_person_query = SQL::Combine::Action::Create::One->new(
            schema => $User,
            query  => $Person->insert(
                values => [
                    id   => $PERSON_ID,
                    name => 'Jim',
                    age  => 25
                ],
            )
        );
        isa_ok($new_person_query, 'SQL::Combine::Action::Create::One');
        ok($new_person_query->is_static, '... the query is static');

        my $comments_query = SQL::Combine::Action::Create::Many->new(
            schema  => $Other,
            queries => [
                $Comment->insert(
                    values => [
                        id       => 5,
                        body     => 'Wassup!',
                        article  => 1,
                        author   => $PERSON_ID
                    ]
                ),
                $Comment->insert(
                    values => [
                        id       => 6,
                        body     => 'DOH!',
                        article  => 1,
                        author   => $PERSON_ID
                    ]
                ),
            ]
        );
        isa_ok($comments_query, 'SQL::Combine::Action::Create::Many');
        ok($comments_query->is_static, '... the query is static');

        $new_person_query->create_related( comments => $comments_query );

        my $new_person_info = $new_person_query->execute;

        #warn Dumper $new_person_info;

        is_deeply(
            $new_person_info,
            { id => 3, comments => { ids => [ 5, 6 ] } },
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

        $person_query->fetch_related(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        my $jim = $person_query->execute;

        is_deeply(
            $jim,
            {
                id       => $PERSON_ID,
                name     => 'Jim',
                age      => 25,
                comments => [
                    {
                        id   => 5,
                        body => 'Wassup!'
                    },
                    {
                        id   => 6,
                        body => 'DOH!'
                    },
                ]
            },
            '... got the selected data as expected'
        );

    };

}

done_testing;
