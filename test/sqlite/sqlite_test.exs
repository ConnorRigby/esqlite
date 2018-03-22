defmodule SqliteTest do
  use ExUnit.Case
  alias Sqlite.{Result}

  describe "open/close" do
    test "opens a database" do
      {:ok, conn} = Sqlite.open(database: "test1.db")
      assert is_pid(conn.pid)
    end

    test "open error" do
      Process.flag(:trap_exit, true)
      Sqlite.open(database: "/dit/bestaat/niet")
      assert_receive {:EXIT, _, {:error, {:cantopen, 'unable to open database file'}}}, 10
    end

    test "close" do
      {:ok, conn} = Sqlite.open(database: "test2.db")
      :ok = Sqlite.close(conn)
    end

    test "Unexpected exit closes db" do
      {:ok, conn} = Sqlite.open(database: ":memory:")
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
      {:ok, conn} = Sqlite.open(database: ":memory:")
      {:ok, %{conn: conn}}
    end

    test "inspect conn", %{conn: conn} do
      assert inspect(conn) =~ "#Sqlite3<"
    end

    test "query", %{conn: conn} do
      {:ok, %Result{num_rows: 0, columns: [], rows: []}} =
        Sqlite.query(conn, "CREATE TABLE posts (id serial, title text, other text)", [])

      {:ok, %Result{num_rows: 0, columns: []}} =
        Sqlite.query(conn, "INSERT INTO posts (id, title, other) VALUES (1000, 'my title', $1)", [
          "testother"
        ])

      {:ok, %Sqlite.Result{columns: [:id], num_rows: 1, rows: [[1000]]}} =
        Sqlite.query(conn, "SELECT id FROM posts WHERE title='my title'", [])

      %Sqlite.Result{columns: [:id], num_rows: 1, rows: [[1000]]}
      Sqlite.query!(conn, "SELECT id FROM posts WHERE title=$1", ["my title"])
    end

    test "query error", %{conn: conn} do
      {:error, %Sqlite.Error{message: m}} = Sqlite.query(conn, "Whoops syntax error", [])
      assert is_binary(m)
      assert m =~ "syntax error"
      {:error, %Sqlite.Error{message: m}} = Sqlite.query(conn, "SELECT nope FROM posts", [])
      assert m == "no such table: posts"

      {:ok, _} = Sqlite.query(conn, "CREATE TABLE posts (id NOT NULL, serial, title text)", [])
      {:error, %Sqlite.Error{message: m}} = Sqlite.query(conn, "SELECT nope FROM posts", [])
      assert m =~ "no such column"

      {:error, %Sqlite.Error{message: m}} =
        Sqlite.query(conn, "INSERT INTO posts (title) VALUES ($1)", ["NULL"])

      assert m =~ "NOT NULL constraint"

      {:error, %Sqlite.Error{message: m}} = Sqlite.query(conn, "SELECT $1 FROM posts", [])
      assert m =~ "args_wrong_length"

      assert_raise Sqlite.Error, "no such column: nope", fn ->
        Sqlite.query!(conn, "SELECT nope FROM posts", [])
      end
    end

    test "prepare", %{conn: conn} do
      {:ok, _query} = Sqlite.prepare(conn, "CREATE TABLE posts (id serial)")
      query = Sqlite.prepare!(conn, "CREATE TABLE loop (id)")
      {:error, %Sqlite.Error{message: m}} = Sqlite.prepare(conn, "WHOOPS")
      assert m =~ "syntax"
      :ok = Sqlite.release_query(conn, query)
      :ok = Sqlite.release_query!(conn, query)

      assert_raise Sqlite.Error, "near \"WHOOPS\": syntax error", fn ->
        Sqlite.prepare!(conn, "WHOOPS")
      end
    end

    test "inspect prepared query.", %{conn: conn} do
      query = Sqlite.prepare!(conn, "CREATE TABLE loop (id)")
      assert inspect(query) =~ "#Statement<"
      empty = %Sqlite.Query{}
      catch_exit(inspect(empty))
    end

    test "execute", %{conn: conn} do
      {:ok, q} = Sqlite.prepare(conn, "CREATE TABLE posts (id serial, title text)")
      {:ok, _} = Sqlite.execute(conn, q, [])
      q = Sqlite.prepare!(conn, "INSERT INTO posts (title) VALUES ($1)")
      {:error, %Sqlite.Error{message: m}} = Sqlite.execute(conn, q, [])
      %Sqlite.Result{} = Sqlite.execute!(conn, q, ["hello!"])
      assert m =~ "args_wrong_length"

      assert_raise Sqlite.Error, "args_wrong_length", fn ->
        Sqlite.execute!(conn, q, [])
      end
    end
  end
end
