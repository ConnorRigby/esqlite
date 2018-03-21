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
  end

  describe "DB modification public api" do
    setup do
      {:ok, conn} = Sqlite.open(database: ":memory:")
      {:ok, %{conn: conn}}
    end

    test "query", %{conn: conn} do
      {:ok, %Result{}} = Sqlite.query(conn, "CREATE TABLE posts (id serial, title text)", [])
      {:ok, %Result{}} = Sqlite.query(conn, "INSERT INTO posts (title) VALUES ('my title')", [])
      {:ok, %Result{}} = Sqlite.query(conn, "SELECT title FROM posts", [])
      {:ok, %Result{}} = Sqlite.query(conn, "SELECT id FROM posts WHERE title like $1", ["%my%"])
      {:ok, %Result{}} = Sqlite.query(conn, "COPY posts TO STDOUT", [])
    end
  end
end
