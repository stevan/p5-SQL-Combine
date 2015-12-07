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

    use_ok('SQL::Combine::Query::Select::RawSQL');

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
                columns => [qw[
                    id
                    title
                    body
                    created
                    updated
                    status
                    approver
                ]]
            )
        ]
    );

    my $Person  = $User->table('person');
    my $Comment = $Other->table('comment');
    my $Article = $Other->table('article');

    subtest '... get article with all relations (raw)' => sub {

        my $ARTICLE_ID = 1;

        my $article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $Other,
            query  => SQL::Combine::Query::Select::RawSQL->new(
                sql          => 'SELECT * FROM article WHERE id = ?',
                bind         => [ $ARTICLE_ID ],
                table_name   => 'article',
                driver       => $DRIVER,
                row_inflator => sub {
                    my ($row) = @_;
                    return +{
                        id       => $row->[0],
                        title    => $row->[1],
                        body     => $row->[2],
                        created  => $row->[3],
                        updated  => $row->[4],
                        status   => $row->[5],
                        approver => $row->[6],
                    }
                }
            )
        );
        isa_ok($article_query, 'SQL::Combine::Action::Fetch::One');
        ok($article_query->is_static, '... the query is static');

        $article_query->relates_to(
            comments => SQL::Combine::Action::Fetch::Many->new(
                schema => $Other,
                query  => SQL::Combine::Query::Select::RawSQL->new(
                    sql          => 'SELECT id, body FROM comment WHERE article = ?',
                    bind         => [ $ARTICLE_ID ],
                    table_name   => 'comment',
                    driver       => $DRIVER,
                    row_inflator => sub {
                        my ($row) = @_;
                        return +{
                            id   => $row->[0],
                            body => $row->[1],
                        }
                    }
                )
            )
        );

        $article_query->relates_to(
            approver => SQL::Combine::Action::Fetch::One->new(
                schema => $User,
                query  => sub {
                    my $result = $_[0];
                    SQL::Combine::Query::Select::RawSQL->new(
                        sql          => 'SELECT id, name, age FROM person WHERE id = ?',
                        bind         => [ $result->{approver} ],
                        table_name   => 'person',
                        driver       => $DRIVER,
                        row_inflator => sub {
                            my ($row) = @_;
                            return +{
                                id   => $row->[0],
                                name => $row->[1],
                                age  => $row->[2],
                            }
                        }
                    )
                }
            )
        );

        my $article = $article_query->execute;

        is_deeply(
            $article,
            {
                id      => 1,
                title   => 'Title(1)',
                body    => 'Body(1)',
                status  => 'pending',
                created => $article->{created},
                updated => $article->{updated},
                comments => [
                    { id => 1, body => 'Yo!' },
                    { id => 2, body => 'Hey!' }
                ],
                approver => {
                    id   => 1,
                    name => 'Bob',
                    age  => 30
                }
            },
            '... got the uninflated stuff as expected'
        );

    };
}

done_testing;
