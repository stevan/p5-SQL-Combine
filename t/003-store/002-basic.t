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

    use_ok('SQL::Combine::Action::Store::One');
    use_ok('SQL::Combine::Action::Store::Many');

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

    my $Person  = $User->table('person');
    my $Comment = $Other->table('comment');

    subtest '... simple insert' => sub {

        my $PERSON_ID = 1;

        my $new_person_query = SQL::Combine::Action::Store::One->new(
            schema => $User,
            query  => $Person->update(
                values => [ age  => 25 ],
                where  => [ id => $PERSON_ID ],
            )
        );
        isa_ok($new_person_query, 'SQL::Combine::Action::Store::One');
        ok($new_person_query->is_static, '... the query is static');

        my $comments_query = SQL::Combine::Action::Store::Many->new(
            schema  => $Other,
            queries => [
                $Comment->update(
                    values => [ body   => '[REDACTED]' ],
                    where  => [ author => $PERSON_ID, body => 'Yo!' ],
                ),
                $Comment->update(
                    values => [ body   => 'Yo! [CITATION NEEDED]' ],
                    where  => [ author => $PERSON_ID, body => 'Yo! (again)' ],
                )
            ]
        );
        isa_ok($comments_query, 'SQL::Combine::Action::Store::Many');
        ok($comments_query->is_static, '... the query is static');

        $new_person_query->store_related( comments => $comments_query );

        my $new_person_info = $new_person_query->execute;

        is_deeply(
            $new_person_info,
            { rows => 1, comments => { rows => [ 1, 1 ] } },
            '... got the expected update info'
        );

        my $person_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query => $Person->select(
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
                    columns => [qw[ body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        my $bob = $person_query->execute;

        is_deeply(
            $bob,
            {
                id       => $PERSON_ID,
                name     => 'Bob',
                age      => 25,
                comments => [
                    { body => '[REDACTED]' },
                    { body => 'Yo! [CITATION NEEDED]' },
                ]
            },
            '... got the selected data as expected'
        );

    };
}

done_testing;
