defmodule SqliteTest do
  use ExUnit.Case
  doctest Sqlite

  test "open a single database" do
    assert match?({:ok, _}, Sqlite.open("test.db"))
  end

  test "open the same database" do
    assert match?({:ok, _}, Sqlite.open("test.db"))
    assert match?({:ok, _}, Sqlite.open("test.db"))
  end

  test "open multiple different databases" do
    assert match?({:ok, _c1}, Sqlite.open("test1.db"))
    assert match?({:ok, _c2}, Sqlite.open("test2.db"))
  end

  test "open with flags" do
    {:ok, db} = Sqlite.open(":memory:", {:readonly})

    {:error, {:readonly, 'attempt to write a readonly database'}} =
      Sqlite.exec("create table test_table(one varchar(10), two int);", db)
  end

  test "subscribe" do
    {:ok, db} = Sqlite.open(":memory:")
    assert :ok = Sqlite.exec("create table test_table(id id, two int);", db)
    assert :ok = Sqlite.subscribe(db)
    :ok = Sqlite.exec(["insert into test_table values(1, 10);"], db)
    assert_receive {'test_table', :insert, 1}

    :ok = Sqlite.exec(["update test_table set two = 20 where id = 1;"], db)
    assert_receive {'test_table', :update, 1}

    :ok = Sqlite.exec(["update test_table set id = 2 where id = 1;"], db)
    assert_receive {'test_table', :update, 1}

    :ok = Sqlite.exec(["delete from test_table where id = 2;"], db)
    assert_receive {'test_table', :delete, 1}
  end

  test "enable loadable extensions" do
    {:ok, db} = Sqlite.open(":memory:")
    assert match?(:ok, Sqlite.enable_load_extension(db))
    :ok = Sqlite.exec("create virtual table test_table using fts3(content text);", db)
  end

  test "simple query" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    {:ok, 1} = Sqlite.changes(db)

    :ok = Sqlite.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    {:ok, 1} = Sqlite.changes(db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    {:ok, 1} = Sqlite.changes(db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    {:ok, 1} = Sqlite.changes(db)
    :ok = Sqlite.exec("commit;", db)
    :ok = Sqlite.exec("select * from test_table;", db)

    :ok = Sqlite.exec("delete from test_table;", db)
    {:ok, 4} = Sqlite.changes(db)
  end

  test "prepare" do
    {:ok, db} = Sqlite.open(":memory:")
    Sqlite.exec("begin;", db)
    Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    {:ok, statement} = Sqlite.prepare("insert into test_table values(\"one\", 2)", db)

    :"$done" = Sqlite.step(statement)
    {:ok, 1} = Sqlite.changes(db)

    :ok = Sqlite.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)

    # Check if the values are there
    [{"one", 2}, {"hello4", 13}] = Sqlite.q("select * from test_table order by two", db)
    Sqlite.exec("commit;", db)
    Sqlite.close(db)
  end

  test "bind" do
    {:ok, db} = Sqlite.open(":memory:")

    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec("commit;", db)

    # Create a prepared statemen
    {:ok, statement} = Sqlite.prepare("insert into test_table values(?1, ?2)", db)
    Sqlite.bind(statement, [:one, 2])
    Sqlite.step(statement)
    Sqlite.bind(statement, ["three", 4])
    Sqlite.step(statement)
    Sqlite.bind(statement, ["five", 6])
    Sqlite.step(statement)
    # iolist bound as text
    Sqlite.bind(statement, [[<<"se">>, <<118>>, "en"], 8])
    Sqlite.step(statement)
    # iolist bound as text
    Sqlite.bind(statement, [<<"nine">>, 10])
    Sqlite.step(statement)
    # iolist bound as blob with trailing eos
    Sqlite.bind(statement, [{:blob, [<<"eleven">>, 0]}, 12])
    Sqlite.step(statement)

    # int6
    Sqlite.bind(statement, [:int64, 308_553_449_069_486_081])
    Sqlite.step(statement)

    # negative int6
    Sqlite.bind(statement, [:negative_int64, -308_553_449_069_486_081])
    Sqlite.step(statement)

    # utf-
    Sqlite.bind(statement, [[<<228, 184, 138, 230, 181, 183>>], 100])
    Sqlite.step(statement)

    assert match?(
             [{<<"one">>, 2}],
             Sqlite.q("select one, two from test_table where two = '2'", db)
           )

    assert match?(
             [{<<"three">>, 4}],
             Sqlite.q("select one, two from test_table where two = 4", db)
           )

    assert match?(
             [{<<"five">>, 6}],
             Sqlite.q("select one, two from test_table where two = 6", db)
           )

    assert match?(
             [{<<"seven">>, 8}],
             Sqlite.q("select one, two from test_table where two = 8", db)
           )

    assert match?(
             [{<<"nine">>, 10}],
             Sqlite.q("select one, two from test_table where two = 10", db)
           )

    assert match?(
             [{{:blob, <<101, 108, 101, 118, 101, 110, 0>>}, 12}],
             Sqlite.q("select one, two from test_table where two = 12", db)
           )

    assert match?(
             [{<<"int64">>, 308_553_449_069_486_081}],
             Sqlite.q("select one, two from test_table where one = 'int64';", db)
           )

    assert match?(
             [{<<"negative_int64">>, -308_553_449_069_486_081}],
             Sqlite.q("select one, two from test_table where one = 'negative_int64';", db)
           )

    # utf-
    assert match?(
             [{<<228, 184, 138, 230, 181, 183>>, 100}],
             Sqlite.q("select one, two from test_table where two = 100", db)
           )
  end

  test "bind for queries" do
    {:ok, db} = Sqlite.open(":memory:")

    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec("commit;", db)

    assert match?(
             [{1}],
             Sqlite.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [:test_table],
               db
             )
           )

    assert match?(
             [{1}],
             Sqlite.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               ["test_table"],
               db
             )
           )

    assert match?(
             [{1}],
             Sqlite.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [<<"test_table">>],
               db
             )
           )

    assert match?(
             [{1}],
             Sqlite.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [[<<"test_table">>]],
               db
             )
           )

    assert match?(
             {:row, {1}},
             Sqlite.exec(
               "SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;",
               [[<<"test_table">>]],
               db
             )
           )
  end

  test "column names" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello2\"", ",", "20);"], db)
    :ok = Sqlite.exec("commit;", db)

    # All column
    {:ok, stmt} = Sqlite.prepare("select * from test_table", db)
    {:one, :two} = Sqlite.column_names(stmt)
    {:row, {<<"hello1">>, 10}} = Sqlite.step(stmt)
    {:one, :two} = Sqlite.column_names(stmt)
    {:row, {<<"hello2">>, 20}} = Sqlite.step(stmt)
    {:one, :two} = Sqlite.column_names(stmt)
    :"$done" = Sqlite.step(stmt)
    {:one, :two} = Sqlite.column_names(stmt)

    # One colum
    {:ok, stmt2} = Sqlite.prepare("select two from test_table", db)
    {:two} = Sqlite.column_names(stmt2)
    {:row, {10}} = Sqlite.step(stmt2)
    {:two} = Sqlite.column_names(stmt2)
    {:row, {20}} = Sqlite.step(stmt2)
    {:two} = Sqlite.column_names(stmt2)
    :"$done" = Sqlite.step(stmt2)
    {:two} = Sqlite.column_names(stmt2)

    # No column
    {:ok, stmt3} = Sqlite.prepare("values(1);", db)
    {:column1} = Sqlite.column_names(stmt3)
    {:row, {1}} = Sqlite.step(stmt3)
    {:column1} = Sqlite.column_names(stmt3)

    # Things get a bit weird when you retrieve the column nam
    # when calling an aggragage function
    {:ok, stmt4} = Sqlite.prepare("select date('now');", db)
    {:"date(\'now\')"} = Sqlite.column_names(stmt4)
    {:row, {date}} = Sqlite.step(stmt4)
    assert is_binary(date)

    # Some statements have no column name
    {:ok, stmt5} = Sqlite.prepare("create table dummy(a, b, c);", db)
    {} = Sqlite.column_names(stmt5)
  end

  test "column types" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello2\"", ",", "20);"], db)
    :ok = Sqlite.exec("commit;", db)

    # All column
    {:ok, stmt} = Sqlite.prepare("select * from test_table", db)
    {:"varchar(10)", :int} = Sqlite.column_types(stmt)
    {:row, {<<"hello1">>, 10}} = Sqlite.step(stmt)
    {:"varchar(10)", :int} = Sqlite.column_types(stmt)
    {:row, {<<"hello2">>, 20}} = Sqlite.step(stmt)
    {:"varchar(10)", :int} = Sqlite.column_types(stmt)
    :"$done" = Sqlite.step(stmt)
    {:"varchar(10)", :int} = Sqlite.column_types(stmt)

    # Some statements have no column type
    {:ok, stmt2} = Sqlite.prepare("create table dummy(a, b, c);", db)
    {} = Sqlite.column_types(stmt2)
  end

  test "nil column types" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table t1(c1 variant);", db)
    :ok = Sqlite.exec("commit;", db)

    {:ok, stmt} = Sqlite.prepare("select c1 + 1, c1 from t1", db)
    {nil, :variant} = Sqlite.column_types(stmt)
  end

  test "reset test" do
    {:ok, db} = Sqlite.open(":memory:")

    {:ok, stmt} = Sqlite.prepare("select * from (values (1), (2));", db)
    {:row, {1}} = Sqlite.step(stmt)

    :ok = Sqlite.reset(stmt)
    {:row, {1}} = Sqlite.step(stmt)
    {:row, {2}} = Sqlite.step(stmt)
    :"$done" = Sqlite.step(stmt)

    # After a done the statement is automatically reset
    {:row, {1}} = Sqlite.step(stmt)

    # Calling reset multiple times..
    :ok = Sqlite.reset(stmt)
    :ok = Sqlite.reset(stmt)
    :ok = Sqlite.reset(stmt)
    :ok = Sqlite.reset(stmt)

    # The statement should still be reset
    {:row, {1}} = Sqlite.step(stmt)
  end

  test "foreach" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    :ok = Sqlite.exec("commit;", db)

    f1 = fn row ->
      case row do
        {key, val} -> :erlang.put(key, val)
      end
    end

    f2 = fn names, row ->
      case row do
        {key, val} -> :erlang.put(key, {names, val})
      end
    end

    Sqlite.foreach(f1, "select * from test_table;", db)
    10 = :erlang.get(<<"hello1">>)
    11 = :erlang.get(<<"hello2">>)
    12 = :erlang.get(<<"hello3">>)
    13 = :erlang.get(<<"hello4">>)

    Sqlite.foreach(f2, "select * from test_table;", db)
    {{:one, :two}, 10} = :erlang.get(<<"hello1">>)
    {{:one, :two}, 11} = :erlang.get(<<"hello2">>)
    {{:one, :two}, 12} = :erlang.get(<<"hello3">>)
    {{:one, :two}, 13} = :erlang.get(<<"hello4">>)
  end

  test "fetchone" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)

    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    {:ok, stmt} = Sqlite.prepare("select * from test_table", db)
    assert match?({"hello1", 10}, Sqlite.fetchone(stmt))
  end

  test "map" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    :ok = Sqlite.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    :ok = Sqlite.exec("commit;", db)

    f = fn row -> row end

    [{<<"hello1">>, 10}, {<<"hello2">>, 11}, {<<"hello3">>, 12}, {<<"hello4">>, 13}] =
      Sqlite.map(f, "select * from test_table", db)

    # Test that when the row-names are added..
    assoc = fn names, row ->
      :lists.zip(:erlang.tuple_to_list(names), :erlang.tuple_to_list(row))
    end

    [
      [{:one, <<"hello1">>}, {:two, 10}],
      [{:one, <<"hello2">>}, {:two, 11}],
      [{:one, <<"hello3">>}, {:two, 12}],
      [{:one, <<"hello4">>}, {:two, 13}]
    ] = Sqlite.map(assoc, "select * from test_table", db)
  end

  test "error1 msg" do
    {:ok, db} = Sqlite.open(":memory:")

    # Not sql
    {:error, {:sqlite_error, _msg1}} = Sqlite.exec("dit is geen sql", db)

    # Database test does not exist
    {:error, {:sqlite_error, _msg2}} = Sqlite.exec("select * from test;", db)

    # Opening non-existant database
    {:error, {:cantopen, _msg3}} = Sqlite.open("/dit/bestaat/niet")
  end

  test "prepare and close connection" do
    {:ok, db} = Sqlite.open(":memory:")

    [] = Sqlite.q("create table test(one, two, three)", db)
    :ok = Sqlite.exec(["insert into test values(1,2,3);"], db)
    {:ok, stmt} = Sqlite.prepare("select * from test", db)

    # The prepared statment works.
    {:row, {1, 2, 3}} = Sqlite.step(stmt)
    :"$done" = Sqlite.step(stmt)

    :ok = Sqlite.close(db)

    :ok = Sqlite.reset(stmt)

    # Internally sqlite3_close_v2 is used by the nif. This will destruct the
    # connection when the last perpared statement is finalized.
    {:row, {1, 2, 3}} = Sqlite.step(stmt)
    :"$done" = Sqlite.step(stmt)
  end

  test "sqlite version" do
    {:ok, db} = Sqlite.open(":memory:")
    {:ok, stmt} = Sqlite.prepare("select sqlite_version() as sqlite_version;", db)
    {:sqlite_version} = Sqlite.column_names(stmt)
    assert match?({:row, {<<"3.24.0">>}}, Sqlite.step(stmt))
  end

  test "sqlite source id" do
    {:ok, db} = Sqlite.open(":memory:")
    {:ok, stmt} = Sqlite.prepare("select sqlite_source_id() as sqlite_source_id;", db)
    {:sqlite_source_id} = Sqlite.column_names(stmt)

    assert match?(
             {:row,
              {<<"2018-06-04 19:24:41 c7ee0833225bfd8c5ec2f9bf62b97c4e04d03bd9566366d5221ac8fb199a87ca">>}},
             Sqlite.step(stmt)
           )
  end

  test "garbage collect" do
    f = fn ->
      {:ok, db} = Sqlite.open(":memory:")
      [] = Sqlite.q("create table test(one, two, three)", db)
      {:ok, stmt} = Sqlite.prepare("select * from test", db)
      :"$done" = Sqlite.step(stmt)
    end

    [spawn(f) || :lists.seq(0, 30)]

    receive do
    after
      500 -> :ok
    end

    :erlang.garbage_collect()

    [spawn(f) || :lists.seq(0, 30)]

    receive do
    after
      500 -> :ok
    end

    :erlang.garbage_collect()
  end

  test "insert" do
    {:ok, db} = Sqlite.open(":memory:")
    :ok = Sqlite.exec("begin;", db)
    :ok = Sqlite.exec("create table test_table(one varchar(10), two int);", db)

    assert match?(
             {:ok, 1},
             Sqlite.insert(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
           )

    assert match?(
             {:ok, 2},
             Sqlite.insert(["insert into test_table values(", "\"hello2\"", ",", "100);"], db)
           )

    :ok = Sqlite.exec("commit;", db)
  end

  test "prepare error" do
    {:ok, db} = Sqlite.open(":memory:")
    Sqlite.exec("begin;", db)
    Sqlite.exec("create table test_table(one varchar(10), two int);", db)

    assert match?(
             {:error, {:sqlite_error, 'near "insurt": syntax error'}},
             Sqlite.prepare("insurt into test_table values(\"one\", 2)", db)
           )

    catch_throw(Sqlite.q("selectt * from test_table order by two", db))
    catch_throw(Sqlite.q("insert into test_table falues(?1, ?2)", [:one, 2], db))

    assoc = fn names, row ->
      :lists.zip(:erlang.tuple_to_list(names), :erlang.tuple_to_list(row))
    end

    catch_throw(Sqlite.map(assoc, "selectt * from test_table", db))
    catch_throw(Sqlite.foreach(assoc, "selectt * from test_table;", db))
  end
end
