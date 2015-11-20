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
}

my $DBH    = 'DBI::db';
my $DRIVER = 'MySQL';

subtest '... testing simple schema-manager' => sub {
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
    isa_ok($m, 'SQL::Combine::Schema::Manager');

    my @schema_names = $m->get_schema_names;
    my @schemas      = $m->get_all_schemas;

    foreach my $i ( 0 ... $#schema_names ) {
        my $name = $schema_names[ $i ];

        my $schema = $m->get_schema_by_name( $name );
        isa_ok($schema, 'SQL::Combine::Schema');

        is($schema, $schemas[$i], '... our schemas should match');

        subtest '... testing the tables inside the schema' => sub {

            my @table_names = $schema->get_table_names;
            my @tables      = $schema->get_all_tables;

            foreach my $i ( 0 ... $#table_names ) {
                my $name = $table_names[ $i ];

                my $table = $schema->get_table_by_name( $name );
                isa_ok($table, 'SQL::Combine::Table');

                is($table, $tables[$i], '... our tables should match');
            }
        };
    }

};

done_testing;
