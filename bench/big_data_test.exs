defmodule BigDataTest do
  use ExUnit.Case
  @timeout :infinity

  @tag :bench
  @tag timeout: @timeout
  test "BIG DATA" do
    {:ok, conn} = Sqlite.open(database: ":memory:")

    column_names_and_types =
      "a int, b int, c int, d int, e int, f int, g int, h int, i int, j int, " <>
        "k int, l int, m int, n int, o int, p int, q int, r int, s int, t int, " <>
        "u int, v int, w int, x int, y int, z int"

    column_names = "a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z"

    subs =
      "$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26"

    {:ok, q} = Sqlite.prepare(conn, "CREATE TABLE posts (#{column_names_and_types})")
    {:ok, _} = Sqlite.execute(conn, q, [])

    {:ok, statement} =
      Sqlite.prepare(conn, "INSERT INTO posts (#{column_names}) VALUES (#{subs})")

    {:ok, _} = Sqlite.execute(conn, statement, Enum.to_list(1..26))
    range = 0..800_000

    inserts_fun = fn ->
      {time, _} =
        :timer.tc(fn ->
          for _i <- range do
            {:ok, _} = Sqlite.execute(conn, statement, Enum.to_list(1..26))
          end
        end)

      IO.puts("#{Enum.count(range)} INSERT's took #{time} µs to execute.")
    end

    query_fun = fn ->
      {time, res} =
        :timer.tc(fn ->
          Sqlite.query!(conn, "SELECT * FROM posts;", [], timeout: @timeout)
        end)

      IO.puts("Query took: #{time} µs.")
      assert match?(%Sqlite.Result{}, res)
    end

    insert_task = Task.async(inserts_fun)
    Task.await(insert_task, @timeout)
    query_task = Task.async(query_fun)
    Task.await(query_task, @timeout)
  end
end
