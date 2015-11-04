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


package Person {
    use Moose;

    has 'id'     => ( is => 'ro', isa => 'Int' );
    has 'name'   => ( is => 'ro', isa => 'Str' );
    has 'age'    => ( is => 'ro', isa => 'Int' );

    has 'comments'  => ( is => 'ro', isa => 'ArrayRef[Comment]' );
    has 'approvals' => ( is => 'ro', isa => 'ArrayRef[Article]' );
}

package Comment {
    use Moose;

    has 'id'   => ( is => 'ro', isa => 'Int' );
    has 'body' => ( is => 'ro', isa => 'Str' );
}

package Article {
    use Moose;

    has 'id'      => (is => 'ro', isa => 'Int' );
    has 'title'   => (is => 'ro', isa => 'Str' );
    has 'body'    => (is => 'ro', isa => 'Str' );
    has 'created' => (is => 'ro', isa => 'Str' );
    has 'updated' => (is => 'ro', isa => 'Str' );
    has 'status'  => (is => 'ro', isa => 'Str' );
}

my $DBH = Util::setup_dbh;

subtest '... get person with all relations (inflated)' => sub {

    my $PERSON_ID = 1;

    my $person_query = SQL::Action::Fetch::One->new(
        composer => SQL::Composer::Select->new(
            from    => 'person',
            columns => [qw[ id name age ]],
            where   => [ id => $PERSON_ID ]
        ),
        inflator => sub {
            my $row = $_[0];
            return Person->new( %$row );
        }
    );

    $person_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body ]],
                where   => [ author => $PERSON_ID ],
            ),
            inflator => sub {
                my $rows = $_[0];
                return [ map { Comment->new( %$_ ) } @$rows ];
            }
        )
    );

    $person_query->fetch_related(
        approvals => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'article',
                columns => [qw[ id title body created updated status ]],
                where   => [ approver => $PERSON_ID ],
            ),
            inflator => sub {
                my $rows = $_[0];
                return [ map { Article->new( %$_ ) } @$rows ];
            }
        )
    );

    my $bob = $person_query->execute( $DBH, {} );
    isa_ok($bob, 'Person');

    is($bob->id, $PERSON_ID, '... got the expected id');
    is($bob->name, 'Bob', '... got the expected name');
    is($bob->age, 30, '... got the expected age');

    my ($comment1, $comment2) = @{ $bob->comments };
    isa_ok($comment1, 'Comment');
    isa_ok($comment2, 'Comment');

    is($comment1->id, 1, '... got the expected id');
    is($comment1->body, 'Yo!', '... got the expected body');

    is($comment2->id, 3, '... got the expected id');
    is($comment2->body, 'Yo! (again)', '... got the expected body');

    my ($article1, $article2) = @{ $bob->approvals };
    isa_ok($article1, 'Article');
    isa_ok($article2, 'Article');

    is($article1->id, 1, '... got the expected id');
    is($article1->title, 'Title(1)', '... got the expected title');
    is($article1->body, 'Body(1)', '... got the expected body');
    is($article1->status, 'pending', '... got the expected status');
    ok($article1->created, '... got a value in created');
    ok($article1->updated, '... got a value in created');

    is($article2->id, 2, '... got the expected id');
    is($article2->title, 'Title(2)', '... got the expected title');
    is($article2->body, 'Body(2)', '... got the expected body');
    is($article2->status, 'pending', '... got the expected status');
    ok($article2->created, '... got a value in created');
    ok($article2->updated, '... got a value in created');
};

subtest '... get person with all relations (raw)' => sub {

    my $PERSON_ID = 1;

    my $person_query = SQL::Action::Fetch::One->new(
        composer => SQL::Composer::Select->new(
            from    => 'person',
            columns => [qw[ id name age ]],
            where   => [ id => $PERSON_ID ]
        )
    );

    $person_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'comment',
                columns => [qw[ id body ]],
                where   => [ author => $PERSON_ID ],
            )
        )
    );

    $person_query->fetch_related(
        approvals => SQL::Action::Fetch::Many->new(
            composer => SQL::Composer::Select->new(
                from    => 'article',
                columns => [qw[ id title body created updated status ]],
                where   => [ approver => $PERSON_ID ],
            )
        )
    );

    my $bob = $person_query->execute( $DBH, {} );

    is_deeply(
        $bob,
        {
            id       => $PERSON_ID,
            name     => 'Bob',
            age      => 30,
            comments => [
                { id => 1, body => 'Yo!' },
                { id => 3, body => 'Yo! (again)' },
            ],
            approvals => [
                {
                    id      => 1,
                    title   => 'Title(1)',
                    body    => 'Body(1)',
                    status  => 'pending',
                    created => $bob->{approvals}->[0]->{created},
                    updated => $bob->{approvals}->[0]->{updated}
                },
                {
                    id      => 2,
                    title   => 'Title(2)',
                    body    => 'Body(2)',
                    status  => 'pending',
                    created => $bob->{approvals}->[1]->{created},
                    updated => $bob->{approvals}->[1]->{updated}
                },
            ]
        },
        '... got the uninflated stuff as expected'
    );

};



done_testing;
