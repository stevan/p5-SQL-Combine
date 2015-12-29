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

    use_ok('SQL::Combine::Action::Sequence');

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

    my $User = SQL::Combine::Schema->new(
        name   => 'user',
        dbh    => { rw => $DBH },
        tables => [
            SQL::Combine::Table->new(
                name   => 'person',
                driver => $DRIVER,
            ),
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
    my $Comment = $User->table('comment');
    my $Article = $User->table('article');

    subtest '... combinators' => sub {

        my $find_jim_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Person->select( columns => [ 'id' ], where => [ name => 'Bob' ] )
        );
        isa_ok($find_jim_query, 'SQL::Combine::Action::Fetch::One');
        ok($find_jim_query->is_static, '... the query is static');

        my $find_article_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => $Article->select( columns => [ 'id' ], where => [ title => 'Title(1)' ] )
        );
        isa_ok($find_article_query, 'SQL::Combine::Action::Fetch::One');
        ok($find_article_query->is_static, '... the query is static');

        my $max_comment_id_query = SQL::Combine::Action::Fetch::One->new(
            schema => $User,
            query  => SQL::Combine::Query::Select::RawSQL->new(
                sql          => 'SELECT MAX(id) FROM comment',
                bind         => [],
                table_name   => 'comment',
                driver       => $DRIVER,
                row_inflator => sub {
                    my ($row) = @_;
                    return +{ max_id => $row->[0] }
                }
            )
        );
        isa_ok($max_comment_id_query, 'SQL::Combine::Action::Fetch::One');
        ok($max_comment_id_query->is_static, '... the query is static');

        my $combined = SQL::Combine::Action::Sequence->new(
            actions => [ $find_article_query, $find_jim_query, $max_comment_id_query ],
        );
        isa_ok($combined, 'SQL::Combine::Action::Sequence');
        ok($combined->is_static, '... the query is static');

        my $comments_query = SQL::Combine::Action::Create::Many->new(
            schema  => $User,
            queries => sub {
                my ($article, $jim, $max_id) = @{$_[0]};
                return +[
                    map $Comment->insert(
                        values => [
                            id       => ++$max_id->{max_id},
                            body     => $_,
                            article  => $article->{id},
                            author   => $jim->{id}
                        ]
                    ), ('Hey', 'Hi', 'Howdy', 'How are you')
                ]
            }
        );
        isa_ok($comments_query, 'SQL::Combine::Action::Create::Many');
        ok(!$comments_query->is_static, '... the query is static');

        $combined->relates_to( comments => $comments_query );

        my $result = $combined->execute;

        is_deeply(
            $result,
            {
                __RESULTS__ => [
                    { id     => 1 },
                    { id     => 1 },
                    { max_id => 8 },
                ],
                comments => { ids => [ 5, 6, 7, 8 ] },
            },
            '... got the expected result'
        )

    };

}

done_testing;
