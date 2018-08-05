[![CircleCI](https://circleci.com/gh/Sqlite-Ecto/elixir_sqlite.svg?style=svg)](https://circleci.com/gh/Sqlite-Ecto/elixir_sqlite)
[![Coverage Status](https://coveralls.io/repos/github/Sqlite-Ecto/elixir_sqlite/badge.svg?branch=master)](https://coveralls.io/github/Sqlite-Ecto/elixir_sqlite?branch=master)
[![Inline docs](http://inch-ci.org/github/Sqlite-Ecto/elixir_sqlite.svg)](http://inch-ci.org/github/Sqlite-Ecto/elixir_sqlite)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_sqlite.svg)](https://hex.pm/packages/elixir_sqlite)
[![Hex.pm](https://img.shields.io/hexpm/dt/elixir_sqlite.svg)](https://hex.pm/packages/elixir_sqlite)


# Sqlite
Elixir API for interacting with SQLite databases.
This library allows you to use the accelent sqlite engine from
erlang. The library is implemented as a nif library, which allows for
the fastest access to a sqlite database. This can be risky, as a bug
in the nif library or the sqlite database can crash the entire Erlang
VM. If you do not want to take this risk, it is always possible to
access the sqlite nif from a separate erlang node.

Special care has been taken not to block the scheduler of the calling
process. This is done by handling all commands from erlang within a
lightweight thread. The erlang scheduler will get control back when
the command has been added to the command-queue of the thread.

# Usage
```elixir
{:ok, db} = Sqlite.open(":memory:")
Sqlite.exec("create virtual table test_table using fts3(content text);", db)
:ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
:ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
{:ok, 1} = Sqlite.changes(db)
```

# Tests
Since this project was originally an Erlang package, I chose to maintain the
original module name (as an alias) and it's tests to try to maintain
backwards compatibility. By default these tests get ran by default.

```bash
# All the tests without the bench marks.
mix test
```

# Benchmarks
There is also a benchmark suite located in the `bench` directory.
It does not get ran with the test suite since it can take quite a while.

```bash
# run all the tests and the benchmarks.
mix test --include bench
```

# Thanks and License
This project is originally a fork of [esqlite](https://github.com/mmzeeman/esqlite)
Which was originally an Erlang implementation. The underlying NIF code (in `c_src`),
and the test file in `erl_test` both retain the original Apache v2 license.
