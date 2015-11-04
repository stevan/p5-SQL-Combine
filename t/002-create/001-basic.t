#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Composer::Insert');
    use_ok('SQL::Composer::Select');

    use_ok('SQL::Action::Create::One');

    use_ok('SQL::Action::Fetch::One');
    use_ok('SQL::Action::Fetch::Many');
}

my $DBH = Util::setup_dbh;

subtest '... simple insert' => sub {

    my $new_person_query = SQL::Action::Create::One->new(
        composer => SQL::Composer::Insert->new(
            into   => 'person',
            values => [
                id   => 3,
                name => 'Jim',
                age  => 25
            ]
        )
    );

    $new_person_query->create_related(
        comments => SQL::Action::Create::One->new(
            composer => sub {
                my $result = $_[0];
                SQL::Composer::Insert->new(
                    into   => 'comment',
                    values => [
                        id       => 5,
                        body     => 'Wassup!',
                        article  => 1,
                        author   => $result->{id}
                    ]
                )
            }
        )
    );

    my $new_person_info = $new_person_query->execute( $DBH, {} );

    is_deeply(
        $new_person_info,
        { id => 3, comments => { id => 5 } },
        '... got the expected data'
    );

    my $person_query = SQL::Action::Fetch::One->new(
        composer => SQL::Composer::Select->new(
            from    => 'person',
            columns => [qw[ id name age ]],
            where   => [ id => $new_person_info->{id} ]
        )
    );

    $person_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body ]],
                where   => [ author => $new_person_info->{id} ],
            )
        )
    );

    my $jim = $person_query->execute( $DBH, {} );

    is_deeply(
        $jim,
        {
            id       => $new_person_info->{id},
            name     => 'Jim',
            age      => 25,
            comments => [
                {
                    id   => $new_person_info->{comments}->{id},
                    body => 'Wassup!'
                },
            ]
        },
        '... got the selected data as expected'
    );

};

done_testing;
