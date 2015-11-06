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

    use_ok('SQL::Action::Create::One');
    use_ok('SQL::Action::Create::Many');

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
        schemas => {
            user     => { rw => $DBH },
            comments => { rw => $DBH },
        }
    );
    isa_ok($dbm, 'SQL::Action::DBH::Manager');

    my $Person = SQL::Action::Table->new(
        schema => 'user',
        name   => 'person',
        driver => $DRIVER,
    );

    my $Comment = SQL::Action::Table->new(
        schema => 'comments',
        name   => 'comment',
        driver => $DRIVER,
    );

    subtest '... simple insert' => sub {

        my $PERSON_ID = 3;

        my $new_person_query = SQL::Action::Create::One->new(
            query  => $Person->insert(
                values => [
                    id   => $PERSON_ID,
                    name => 'Jim',
                    age  => 25
                ],
            )
        );

        $new_person_query->create_related(
            comments => SQL::Action::Create::Many->new(
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
            )
        );

        my $new_person_info = $new_person_query->execute( $dbm, {} );

        is_deeply(
            $new_person_info,
            { id => 3, comments => { ids => [ 5, 6 ] } },
            '... got the expected insert info'
        );

        my $person_query = SQL::Action::Fetch::One->new(
            query  => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );

        $person_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        my $jim = $person_query->execute( $dbm, {} );

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
