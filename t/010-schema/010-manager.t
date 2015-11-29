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
}

my $DBH    = 'DBI::db';
my $DRIVER = 'MySQL';

subtest '... testing simple schema' => sub {

    my @schemas = (
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
    );

    my @schema_names = map $_->name, @schemas;

    foreach my $i ( 0 ... $#schema_names ) {
        my $name   = $schema_names[ $i ];
        my $schema = $schemas[$i];

        isa_ok($schema, 'SQL::Combine::Schema');

        is($schema->name, $name, '... our schemas name should match');

        subtest '... testing the tables inside the schema' => sub {

            my @tables      = @{ $schema->tables };
            my @table_names = map $_->name, @tables;

            foreach my $i ( 0 ... $#table_names ) {
                my $name = $table_names[ $i ];

                my $table = $schema->table( $name );
                isa_ok($table, 'SQL::Combine::Table');

                is($table, $tables[$i], '... our tables should match');
            }
        };
    }

};

done_testing;
