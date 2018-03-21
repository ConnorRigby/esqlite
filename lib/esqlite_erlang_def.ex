defmodule :esqlite3 do
  mod_docs = Code.get_docs(Esqlite3, :moduledoc)

  if mod_docs do
    @moduledoc elem(mod_docs, 1)
  end

  docs =
    (Code.get_docs(Esqlite3, :docs) || [])
    |> Enum.map(fn {name, _, _, _, data} -> {name, data} end)
    |> Map.new()

  @doc docs[{:open, 1}]
  defdelegate open(filename), to: Esqlite3

  @doc docs[{:open, 2}]
  defdelegate open(filename, timeout), to: Esqlite3

  @doc docs[{:exec, 2}]
  defdelegate exec(sql, connection), to: Esqlite3

  @doc docs[{:exec, 3}]
  defdelegate exec(sql, params, connection), to: Esqlite3

  @doc docs[{:changes, 1}]
  defdelegate changes(connection), to: Esqlite3

  @doc docs[{:changes, 2}]
  defdelegate changes(connection, timeout), to: Esqlite3

  @doc docs[{:insert, 2}]
  defdelegate insert(sql, connection), to: Esqlite3

  @doc docs[{:insert, 3}]
  defdelegate insert(sql, connection, timeout), to: Esqlite3

  @doc docs[{:prepare, 2}]
  defdelegate prepare(sql, connection), to: Esqlite3

  @doc docs[{:prepare, 3}]
  defdelegate prepare(sql, connection, timeout), to: Esqlite3

  @doc docs[{:step, 1}]
  defdelegate step(statement), to: Esqlite3

  @doc docs[{:step, 2}]
  defdelegate step(statement, timeout), to: Esqlite3

  @doc docs[{:reset, 1}]
  defdelegate reset(prepared_statement), to: Esqlite3

  @doc docs[{:reset, 2}]
  defdelegate reset(prepared_statement, timeout), to: Esqlite3

  @doc docs[{:bind, 2}]
  defdelegate bind(statement, args), to: Esqlite3

  @doc docs[{:bind, 3}]
  defdelegate bind(prepared_statement, args, timeout), to: Esqlite3

  @doc docs[{:column_names, 1}]
  defdelegate column_names(statement), to: Esqlite3

  @doc docs[{:column_names, 2}]
  defdelegate column_names(statement, timeout), to: Esqlite3

  @doc docs[{:column_types, 1}]
  defdelegate column_types(statement), to: Esqlite3

  @doc docs[{:column_types, 2}]
  defdelegate column_types(statement, timeout), to: Esqlite3

  @doc docs[{:close, 1}]
  defdelegate close(connection), to: Esqlite3

  @doc docs[{:close, 2}]
  defdelegate close(connection, timeout), to: Esqlite3

  @doc docs[{:fetchone, 1}]
  defdelegate fetchone(statement), to: Esqlite3

  @doc docs[{:fetchall, 2}]
  defdelegate fetchall(statement), to: Esqlite3

  @doc docs[{:q, 2}]
  defdelegate q(sql, connection), to: Esqlite3

  @doc docs[{:q, 3}]
  defdelegate q(sql, args, connection), to: Esqlite3

  @doc docs[{:map, 3}]
  defdelegate map(f, sql, connection), to: Esqlite3

  @doc docs[{:foreach, 3}]
  defdelegate foreach(f, sql, connection), to: Esqlite3
end
