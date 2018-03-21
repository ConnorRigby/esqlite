defmodule Esqlite3Test do
  use ExUnit.Case
  doctest Esqlite3

  test "open a single database" do
    assert match?({:ok, _}, Esqlite3.open("test.db"))
  end

  test "open the same database" do
    assert match?({:ok, _}, Esqlite3.open("test.db"))
    assert match?({:ok, _}, Esqlite3.open("test.db"))
  end

  test "open multiple different databases" do
    assert match?({:ok, _c1}, Esqlite3.open("test1.db"))
    assert match?({:ok, _c2}, Esqlite3.open("test2.db"))
  end

  test "simple query" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    {:ok, 1} = Esqlite3.changes(db)

    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    {:ok, 1} = Esqlite3.changes(db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    {:ok, 1} = Esqlite3.changes(db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    {:ok, 1} = Esqlite3.changes(db)
    :ok = Esqlite3.exec("commit;", db)
    :ok = Esqlite3.exec("select * from test_table;", db)

    :ok = Esqlite3.exec("delete from test_table;", db)
    {:ok, 4} = Esqlite3.changes(db)
  end

  test "prepare" do
    {:ok, db} = Esqlite3.open(":memory:")
    Esqlite3.exec("begin;", db)
    Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    {:ok, statement} = Esqlite3.prepare("insert into test_table values(\"one\", 2)", db)

    :"$done" = Esqlite3.step(statement)
    {:ok, 1} = Esqlite3.changes(db)

    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)

    # Check if the values are there
    [{"one", 2}, {"hello4", 13}] = Esqlite3.q("select * from test_table order by two", db)
    Esqlite3.exec("commit;", db)
    Esqlite3.close(db)
  end

  test "bind" do
    {:ok, db} = Esqlite3.open(":memory:")

    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec("commit;", db)

    # Create a prepared statemen
    {:ok, statement} = Esqlite3.prepare("insert into test_table values(?1, ?2)", db)
    Esqlite3.bind(statement, [:one, 2])
    Esqlite3.step(statement)
    Esqlite3.bind(statement, ["three", 4])
    Esqlite3.step(statement)
    Esqlite3.bind(statement, ["five", 6])
    Esqlite3.step(statement)
    # iolist bound as text
    Esqlite3.bind(statement, [[<<"se">>, <<118>>, "en"], 8])
    Esqlite3.step(statement)
    # iolist bound as text
    Esqlite3.bind(statement, [<<"nine">>, 10])
    Esqlite3.step(statement)
    # iolist bound as blob with trailing eos
    Esqlite3.bind(statement, [{:blob, [<<"eleven">>, 0]}, 12])
    Esqlite3.step(statement)

    # int6
    Esqlite3.bind(statement, [:int64, 308_553_449_069_486_081])
    Esqlite3.step(statement)

    # negative int6
    Esqlite3.bind(statement, [:negative_int64, -308_553_449_069_486_081])
    Esqlite3.step(statement)

    # utf-
    Esqlite3.bind(statement, [[<<228, 184, 138, 230, 181, 183>>], 100])
    Esqlite3.step(statement)

    assert match?(
             [{<<"one">>, 2}],
             Esqlite3.q("select one, two from test_table where two = '2'", db)
           )

    assert match?(
             [{<<"three">>, 4}],
             Esqlite3.q("select one, two from test_table where two = 4", db)
           )

    assert match?(
             [{<<"five">>, 6}],
             Esqlite3.q("select one, two from test_table where two = 6", db)
           )

    assert match?(
             [{<<"seven">>, 8}],
             Esqlite3.q("select one, two from test_table where two = 8", db)
           )

    assert match?(
             [{<<"nine">>, 10}],
             Esqlite3.q("select one, two from test_table where two = 10", db)
           )

    assert match?(
             [{{:blob, <<101, 108, 101, 118, 101, 110, 0>>}, 12}],
             Esqlite3.q("select one, two from test_table where two = 12", db)
           )

    assert match?(
             [{<<"int64">>, 308_553_449_069_486_081}],
             Esqlite3.q("select one, two from test_table where one = 'int64';", db)
           )

    assert match?(
             [{<<"negative_int64">>, -308_553_449_069_486_081}],
             Esqlite3.q("select one, two from test_table where one = 'negative_int64';", db)
           )

    # utf-
    assert match?(
             [{<<228, 184, 138, 230, 181, 183>>, 100}],
             Esqlite3.q("select one, two from test_table where two = 100", db)
           )
  end

  test "bind for queries" do
    {:ok, db} = Esqlite3.open(":memory:")

    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec("commit;", db)

    assert match?(
             [{1}],
             Esqlite3.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [:test_table],
               db
             )
           )

    assert match?(
             [{1}],
             Esqlite3.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               ["test_table"],
               db
             )
           )

    assert match?(
             [{1}],
             Esqlite3.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [<<"test_table">>],
               db
             )
           )

    assert match?(
             [{1}],
             Esqlite3.q(
               <<"SELECT count(type) FROM sqlite_master WHERE type='table' AND name=?;">>,
               [[<<"test_table">>]],
               db
             )
           )
  end

  test "column names" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello2\"", ",", "20);"], db)
    :ok = Esqlite3.exec("commit;", db)

    # All column
    {:ok, stmt} = Esqlite3.prepare("select * from test_table", db)
    {:one, :two} = Esqlite3.column_names(stmt)
    {:row, {<<"hello1">>, 10}} = Esqlite3.step(stmt)
    {:one, :two} = Esqlite3.column_names(stmt)
    {:row, {<<"hello2">>, 20}} = Esqlite3.step(stmt)
    {:one, :two} = Esqlite3.column_names(stmt)
    :"$done" = Esqlite3.step(stmt)
    {:one, :two} = Esqlite3.column_names(stmt)

    # One colum
    {:ok, stmt2} = Esqlite3.prepare("select two from test_table", db)
    {:two} = Esqlite3.column_names(stmt2)
    {:row, {10}} = Esqlite3.step(stmt2)
    {:two} = Esqlite3.column_names(stmt2)
    {:row, {20}} = Esqlite3.step(stmt2)
    {:two} = Esqlite3.column_names(stmt2)
    :"$done" = Esqlite3.step(stmt2)
    {:two} = Esqlite3.column_names(stmt2)

    # No column
    {:ok, stmt3} = Esqlite3.prepare("values(1);", db)
    {:column1} = Esqlite3.column_names(stmt3)
    {:row, {1}} = Esqlite3.step(stmt3)
    {:column1} = Esqlite3.column_names(stmt3)

    # Things get a bit weird when you retrieve the column nam
    # when calling an aggragage function
    {:ok, stmt4} = Esqlite3.prepare("select date('now');", db)
    {:"date(\'now\')"} = Esqlite3.column_names(stmt4)
    {:row, {date}} = Esqlite3.step(stmt4)
    assert is_binary(date)

    # Some statements have no column name
    {:ok, stmt5} = Esqlite3.prepare("create table dummy(a, b, c);", db)
    {} = Esqlite3.column_names(stmt5)
  end

  test "column types" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello2\"", ",", "20);"], db)
    :ok = Esqlite3.exec("commit;", db)

    # All column
    {:ok, stmt} = Esqlite3.prepare("select * from test_table", db)
    {:"varchar(10)", :int} = Esqlite3.column_types(stmt)
    {:row, {<<"hello1">>, 10}} = Esqlite3.step(stmt)
    {:"varchar(10)", :int} = Esqlite3.column_types(stmt)
    {:row, {<<"hello2">>, 20}} = Esqlite3.step(stmt)
    {:"varchar(10)", :int} = Esqlite3.column_types(stmt)
    :"$done" = Esqlite3.step(stmt)
    {:"varchar(10)", :int} = Esqlite3.column_types(stmt)

    # Some statements have no column type
    {:ok, stmt2} = Esqlite3.prepare("create table dummy(a, b, c);", db)
    {} = Esqlite3.column_types(stmt2)
  end

  test "nil column types" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table t1(c1 variant);", db)
    :ok = Esqlite3.exec("commit;", db)

    {:ok, stmt} = Esqlite3.prepare("select c1 + 1, c1 from t1", db)
    {nil, :variant} = Esqlite3.column_types(stmt)
  end

  test "reset test" do
    {:ok, db} = Esqlite3.open(":memory:")

    {:ok, stmt} = Esqlite3.prepare("select * from (values (1), (2));", db)
    {:row, {1}} = Esqlite3.step(stmt)

    :ok = Esqlite3.reset(stmt)
    {:row, {1}} = Esqlite3.step(stmt)
    {:row, {2}} = Esqlite3.step(stmt)
    :"$done" = Esqlite3.step(stmt)

    # After a done the statement is automatically reset
    {:row, {1}} = Esqlite3.step(stmt)

    # Calling reset multiple times..
    :ok = Esqlite3.reset(stmt)
    :ok = Esqlite3.reset(stmt)
    :ok = Esqlite3.reset(stmt)
    :ok = Esqlite3.reset(stmt)

    # The statement should still be reset
    {:row, {1}} = Esqlite3.step(stmt)
  end

  test "foreach" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    :ok = Esqlite3.exec("commit;", db)

    f = fn row ->
      case row do
        {key, val} -> :erlang.put(key, val)
        _ -> :ok
      end
    end

    Esqlite3.foreach(f, "select * from test_table;", db)
    10 = :erlang.get(<<"hello1">>)
    11 = :erlang.get(<<"hello2">>)
    12 = :erlang.get(<<"hello3">>)
    13 = :erlang.get(<<"hello4">>)
  end

  test "map" do
    {:ok, db} = Esqlite3.open(":memory:")
    :ok = Esqlite3.exec("begin;", db)
    :ok = Esqlite3.exec("create table test_table(one varchar(10), two int);", db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello1\"", ",", "10);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello2\"", ",", "11);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello3\"", ",", "12);"], db)
    :ok = Esqlite3.exec(["insert into test_table values(", "\"hello4\"", ",", "13);"], db)
    :ok = Esqlite3.exec("commit;", db)

    f = fn row -> row end

    [{<<"hello1">>, 10}, {<<"hello2">>, 11}, {<<"hello3">>, 12}, {<<"hello4">>, 13}] =
      Esqlite3.map(f, "select * from test_table", db)

    # Test that when the row-names are added..
    assoc = fn names, row ->
      :lists.zip(:erlang.tuple_to_list(names), :erlang.tuple_to_list(row))
    end

    [
      [{:one, <<"hello1">>}, {:two, 10}],
      [{:one, <<"hello2">>}, {:two, 11}],
      [{:one, <<"hello3">>}, {:two, 12}],
      [{:one, <<"hello4">>}, {:two, 13}]
    ] = Esqlite3.map(assoc, "select * from test_table", db)
  end

  test "error1 msg" do
    {:ok, db} = Esqlite3.open(":memory:")

    # Not sql
    {:error, {:sqlite_error, _Msg1}} = Esqlite3.exec("dit is geen sql", db)

    # Database test does not exist
    {:error, {:sqlite_error, _Msg2}} = Esqlite3.exec("select * from test;", db)

    # Opening non-existant database
    {:error, {:cantopen, _Msg3}} = Esqlite3.open("/dit/bestaat/niet")
  end

  test "prepare and close connection" do
    {:ok, db} = Esqlite3.open(":memory:")

    [] = Esqlite3.q("create table test(one, two, three)", db)
    :ok = Esqlite3.exec(["insert into test values(1,2,3);"], db)
    {:ok, stmt} = Esqlite3.prepare("select * from test", db)

    # The prepared statment works.
    {:row, {1, 2, 3}} = Esqlite3.step(stmt)
    :"$done" = Esqlite3.step(stmt)

    :ok = Esqlite3.close(db)

    :ok = Esqlite3.reset(stmt)

    # Internally sqlite3_close_v2 is used by the nif. This will destruct the
    # connection when the last perpared statement is finalized.
    {:row, {1, 2, 3}} = Esqlite3.step(stmt)
    :"$done" = Esqlite3.step(stmt)
  end

  test "sqlite version" do
    {:ok, db} = Esqlite3.open(":memory:")
    {:ok, stmt} = Esqlite3.prepare("select sqlite_version() as sqlite_version;", db)
    {:sqlite_version} = Esqlite3.column_names(stmt)
    assert match?({:row, {<<"3.18.0">>}}, Esqlite3.step(stmt))
  end

  test "sqlite source id" do
    {:ok, db} = Esqlite3.open(":memory:")
    {:ok, stmt} = Esqlite3.prepare("select sqlite_source_id() as sqlite_source_id;", db)
    {:sqlite_source_id} = Esqlite3.column_names(stmt)

    assert match?(
             {:row,
              {<<"2017-03-28 18:48:43 424a0d380332858ee55bdebc4af3789f74e70a2b3ba1cf29d84b9b4bcf3e2e37">>}},
             Esqlite3.step(stmt)
           )
  end

  test "garbage collect" do
    f = fn ->
      {:ok, db} = Esqlite3.open(":memory:")
      [] = Esqlite3.q("create table test(one, two, three)", db)
      {:ok, stmt} = Esqlite3.prepare("select * from test", db)
      :"$done" = Esqlite3.step(stmt)
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
end
