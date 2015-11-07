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

    use_ok('SQL::Combine::Store::One');
    use_ok('SQL::Combine::Store::Many');

    use_ok('SQL::Combine::Fetch::One');
    use_ok('SQL::Combine::Fetch::Many');
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
            user     => { rw => $DBH },
            comments => { rw => $DBH },
        }
    );
    isa_ok($dbm, 'SQL::Combine::DBH::Manager');

    my $Person = SQL::Combine::Table->new(
        schema => 'user',
        name   => 'person',
        driver => $DRIVER,
    );

    my $Comment = SQL::Combine::Table->new(
        schema => 'comments',
        name   => 'comment',
        driver => $DRIVER,
    );

    subtest '... simple insert' => sub {

        my $PERSON_ID = 1;

        my $new_person_query = SQL::Combine::Store::One->new(
            query => $Person->update(
                values => [ age  => 25 ],
                where  => [ id => $PERSON_ID ],
            )
        );

        $new_person_query->store_related(
            comments => SQL::Combine::Store::Many->new(
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
            )
        );

        my $new_person_info = $new_person_query->execute( $dbm, {} );

        is_deeply(
            $new_person_info,
            { rows => 1, comments => { rows => [ 1, 1 ] } },
            '... got the expected update info'
        );

        my $person_query = SQL::Combine::Fetch::One->new(
            schema => 'user',
            query => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );

        $person_query->fetch_related(
            comments => SQL::Combine::Fetch::Many->new(
                schema => 'comments',
                query => $Comment->select(
                    columns => [qw[ body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        my $bob = $person_query->execute( $dbm, {} );

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
