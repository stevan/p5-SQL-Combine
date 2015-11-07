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
        schemas => {
            __DEFAULT__ => { rw => $DBH },
        }
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

    subtest '... get person with all relations (raw)' => sub {

        my $PERSON_ID = 1;

        my $person_query = SQL::Action::Fetch::One->new(
            query => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );

        $person_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        $person_query->fetch_related(
            approvals => SQL::Action::Fetch::Many->new(
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
}


done_testing;
