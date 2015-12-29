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

    use_ok('SQL::Combine::Action::Fetch::One');
    use_ok('SQL::Combine::Action::Fetch::Many');
}

package Person {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        bless { @_ } => $class;
    }

    sub id   { $_[0]->{id}   }
    sub name { $_[0]->{name} }
    sub age  { $_[0]->{age}  }

    sub comments  { $_[0]->{comments}  }
    sub approvals { $_[0]->{approvals} }
}

package Comment {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        bless { @_ } => $class;
    }

    sub id   { $_[0]->{id}   }
    sub body { $_[0]->{body} }
}

package Article {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        bless { @_ } => $class;
    }

    sub id      { $_[0]->{id}      }
    sub title   { $_[0]->{title}   }
    sub body    { $_[0]->{body}    }
    sub created { $_[0]->{created} }
    sub updated { $_[0]->{updated} }
    sub status  { $_[0]->{status}  }
}


my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $User = SQL::Combine::Schema->new(
        name   => 'user',
        dbh    => { rw => $DBH },
        tables => [
            SQL::Combine::Table->new(
                name       => 'Person',
                table_name => 'person',
                driver     => $DRIVER,
            )
        ]
    );
    my $Other = SQL::Combine::Schema->new(
        name   => 'other',
        dbh    => { rw => $DBH },
        tables => [
            SQL::Combine::Table->new(
                name       => 'Comment',
                table_name => 'comment',
                driver     => $DRIVER,
            ),
            SQL::Combine::Table->new(
                name       => 'Article',
                table_name => 'article',
                driver     => $DRIVER,
            )
        ]
    );

    my $Person  = $User->table('Person');
    my $Comment = $Other->table('Comment');
    my $Article = $Other->table('Article');

    subtest '... get person with all relations (inflated)' => sub {

        my $PERSON_ID = 1;

        my $person_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            ),
            inflator => sub {
                my $row = $_[0];
                return Person->new( %$row );
            }
        );
        isa_ok($person_query, 'SQL::Combine::Action::Fetch::One');
        ok($person_query->is_static, '... the query is static');

        $person_query->relates_to(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => $Comment->select(
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                ),
                inflator => sub {
                    my $rows = $_[0];
                    return [ map { Comment->new( %$_ ) } @$rows ];
                }
            )
        );

        $person_query->relates_to(
            approvals => SQL::Combine::Action::Fetch::Many->new(
                schema => $User,
                query  => $Article->select(
                    columns => [qw[ id title body created updated status ]],
                    where   => [ approver => $PERSON_ID ],
                ),
                inflator => sub {
                    my $rows = $_[0];
                    return [ map { Article->new( %$_ ) } @$rows ];
                }
            )
        );

        my $bob = $person_query->execute;
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
                    columns => [qw[ id body ]],
                    where   => [ author => $PERSON_ID ],
                )
            )
        );

        $person_query->relates_to(
            approvals => SQL::Combine::Action::Fetch::Many->new(
                schema => $User,
                query  => $Article->select(
                    columns => [qw[ id title body created updated status ]],
                    where   => [ approver => $PERSON_ID ],
                )
            )
        );

        my $bob = $person_query->execute;

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
}


done_testing;
