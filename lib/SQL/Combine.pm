package SQL::Combine;

use strict;
use warnings;

__END__

=pod

=head1 NAME

SQL::Combine - Yet Another SQL Framework

=head1 DESCRIPTION

You can think of this is kind of an anti-ORM framework.

The goal of this module is to not try to map objects to table rows,
but instead to provide a more SQL-oriented programming experience
that makes better use of the inherent strengths of the underlying
databases.

=head2 What is wrong with ORMs?

ORM, meaning Object-Relational Mapper, is a common tool in the modern
programmers toolset, but it is a deeply flawed one. ORMs suffer from
what is called the "impedence mismatch", meaning that the conceptual
underpinnings of a RDBMS and of Object Oriented programming do not
match. The best way I know of to explain this is to point out the
different ways in which data is organized and linked within these
two conceptual frameworks.

=over 4

=item SQL Databases

SQL database data is organized in sets and tuples whcih are related
to one another implictly using shared values.

=item Object Oriention

Within an OO program data is organized into graphs of objcts that
contain explicit relationships using memory pointers.

=back

=head1 CONCEPTS

There are four main concepts in this framework; Statements and
Queries, Actions, Schemas and finally Tables. Every effort has
been made to keep these abstractions as close to the ideas they
model.

=head2 Statements and Queries

The primary means of interacting with a SQL database is through
queries and statements, however that is only what the database
should do, from there it is the responsibility of the user to
do something with the results. This is not an issue given a
single SQL query, but often times there is a need to have
several coordinating queries working together in some way, this
is where Actions come in.

=head2 Actions

Actions can be thought of as encapsulating a single Unit of Work,
which is composed of a set of Queries and/or Statements meant to
produce a specified result. Unlike SQL statements, an Action is
not confined to a single database, it is possible to use Actions
to weave together data from many different databases into one
unit of work.

=head2 Schemas

Schemas are a means of associating a set of Table instances with
a set of database connections for a given server.

=head2 Tables

Tables are a thin wrapper around a database table and contain
metadata and a set of methods which build Statement and Query
objects related to the table.

=cut
