defmodule Sqlite.Connection.Test do
  use ExUnit.Case
  alias Sqlite.{Connection, Error, Query, Result}

  describe "open/close" do
    test "opens a database" do
      {:ok, conn} = Connection.open(database: "test1.db")
      assert is_pid(conn.pid)
    end

    test "open error" do
      Process.flag(:trap_exit, true)
      Connection.open(database: "/dit/bestaat/niet")
      assert_receive {:EXIT, _, {:error, {:cantopen, 'unable to open database file'}}}, 10
    end

    test "close" do
      {:ok, conn} = Connection.open(database: "test2.db")
      :ok = Connection.close(conn)
    end

    test "Unexpected exit closes db" do
      {:ok, conn} = Connection.open(database: ":memory:")
      pid = conn.pid
      assert is_pid(pid)
      assert Process.alive?(pid)
      Process.flag(:trap_exit, true)
      GenServer.stop(pid, :normal)
      assert_receive {:EXIT, ^pid, :normal}, 10
      refute Process.alive?(pid)
    end
  end

  describe "DB modification public api" do
    setup do
      {:ok, conn} = Connection.open(database: ":memory:")
      {:ok, %{conn: conn}}
    end

    test "inspect conn", %{conn: conn} do
      assert inspect(conn) =~ "#Sqlite3<"
    end

    test "query", %{conn: conn} do
      {:ok, %Result{num_rows: 0, columns: [], rows: []}} =
        Connection.query(conn, "CREATE TABLE posts (id serial, title text, other text)", [])

      {:ok, %Result{num_rows: 0, columns: []}} =
        Connection.query(conn, "INSERT INTO posts (id, title, other) VALUES (1000, 'my title', $1)", [
          "testother"
        ])

      {:ok, %Result{columns: [:id], num_rows: 1, rows: [[1000]]}} =
        Connection.query(conn, "SELECT id FROM posts WHERE title='my title'", [])

      %Result{columns: [:id], num_rows: 1, rows: [[1000]]}
      Connection.query!(conn, "SELECT id FROM posts WHERE title=$1", ["my title"])
    end

    test "query error", %{conn: conn} do
      {:error, %Error{message: m}} = Connection.query(conn, "Whoops syntax error", [])
      assert is_binary(m)
      assert m =~ "syntax error"
      {:error, %Error{message: m}} = Connection.query(conn, "SELECT nope FROM posts", [])
      assert m == "no such table: posts"

      {:ok, _} = Connection.query(conn, "CREATE TABLE posts (id NOT NULL, serial, title text)", [])
      {:error, %Error{message: m}} = Connection.query(conn, "SELECT nope FROM posts", [])
      assert m =~ "no such column"

      {:error, %Error{message: m}} =
        Connection.query(conn, "INSERT INTO posts (title) VALUES ($1)", ["NULL"])

      assert m =~ "NOT NULL constraint"

      {:error, %Error{message: m}} = Connection.query(conn, "SELECT $1 FROM posts", [])
      assert m =~ "args_wrong_length"

      assert_raise Error, "no such column: nope", fn ->
        Connection.query!(conn, "SELECT nope FROM posts", [])
      end
    end

    test "prepare", %{conn: conn} do
      {:ok, _query} = Connection.prepare(conn, "CREATE TABLE posts (id serial)")
      query = Connection.prepare!(conn, "CREATE TABLE loop (id)")
      {:error, %Error{message: m}} = Connection.prepare(conn, "WHOOPS")
      assert m =~ "syntax"
      :ok = Connection.release_query(conn, query)
      :ok = Connection.release_query!(conn, query)

      assert_raise Error, "near \"WHOOPS\": syntax error", fn ->
        Connection.prepare!(conn, "WHOOPS")
      end
    end

    test "inspect prepared query.", %{conn: conn} do
      query = Connection.prepare!(conn, "CREATE TABLE loop (id)")
      assert inspect(query) =~ "#Statement<"
      empty = %Sqlite.Query{}
      catch_exit(inspect(empty))
    end

    test "execute", %{conn: conn} do
      {:ok, q} = Connection.prepare(conn, "CREATE TABLE posts (id serial, title text)")
      {:ok, _} = Connection.execute(conn, q, [])
      q = Connection.prepare!(conn, "INSERT INTO posts (title) VALUES ($1)")
      {:error, %Error{message: m}} = Connection.execute(conn, q, [])
      %Result{} = Connection.execute!(conn, q, ["hello!"])
      assert m =~ "args_wrong_length"

      assert_raise Error, "args_wrong_length", fn ->
        Connection.execute!(conn, q, [])
      end
    end
  end
end
