package Util;

use strict;
use warnings;

use DBI;

sub setup_dbh {
    my $DBH = DBI->connect(
        ('dbi:SQLite:dbname=:memory:', '', ''),
        {
            PrintError => 0,
            RaiseError => 1,
        }
    );

    $DBH->do(q[
        CREATE TABLE `article` (
            `id`            INTEGER     PRIMARY KEY,
            `title`         TEXT        NOT NULL,
            `body`          TEXT        NOT NULL,
            `created`       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
            `updated`       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
            `status`        TEXT        NOT NULL   DEFAULT "pending",
            `approver`      INTEGER
        )
    ]);

    $DBH->do(q[
        CREATE TABLE `person` (
            `id`            INTEGER     PRIMARY KEY,
            `name`          TEXT        NOT NULL   DEFAULT "anonymous",
            `age`           INTEGER     NOT NULL   DEFAULT "100"
        )
    ]);

    $DBH->do(q[
        CREATE TABLE `comment` (
            `id`            INTEGER     PRIMARY KEY,
            `body`          TEXT        NOT NULL DEFAULT "",
            `author`        INTEGER     NOT NULL,
            `article`       INTEGER     NOT NULL
        )
    ]);

    $DBH->do(q[ INSERT INTO `article` (`id`, `title`, `body`, `approver`) VALUES(1, "Title(1)", "Body(1)", 1) ]);
    $DBH->do(q[ INSERT INTO `article` (`id`, `title`, `body`, `approver`) VALUES(2, "Title(2)", "Body(2)", 1) ]);

    $DBH->do(q[ INSERT INTO `person` (`id`, `name`, `age`) VALUES(1, "Bob", 30) ]);
    $DBH->do(q[ INSERT INTO `person` (`id`, `name`, `age`) VALUES(2, "Alice", 32) ]);

    $DBH->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(1, "Yo!", 1, 1) ]);
    $DBH->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(2, "Hey!", 2, 1) ]);

    $DBH->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(3, "Yo! (again)", 1, 2) ]);
    $DBH->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(4, "Hey! (again)", 2, 2) ]);

    return $DBH;
}

1;
