defmodule :esqlite3 do
  defdelegate open(filename), to: Esqlite3
  defdelegate open(filename, timeout), to: Esqlite3
  defdelegate exec(sql, connection), to: Esqlite3
  defdelegate exec(sql, params, connection), to: Esqlite3
  defdelegate changes(connection), to: Esqlite3
  defdelegate changes(connection, timeout), to: Esqlite3
  defdelegate insert(sql, connection), to: Esqlite3
  defdelegate insert(sql, connection, timeout), to: Esqlite3
  defdelegate prepare(sql, connection), to: Esqlite3
  defdelegate prepare(sql, connection, timeout), to: Esqlite3
  defdelegate step(statement), to: Esqlite3
  defdelegate step(statement, timeout), to: Esqlite3
  defdelegate reset(prepared_statement), to: Esqlite3
  defdelegate reset(prepared_statement, timeout), to: Esqlite3
  defdelegate bind(statement, args), to: Esqlite3
  defdelegate bind(prepared_statement, args, timeout), to: Esqlite3
  defdelegate column_names(statement), to: Esqlite3
  defdelegate column_names(statement, timeout), to: Esqlite3
  defdelegate column_types(statement), to: Esqlite3
  defdelegate column_types(statement, timeout), to: Esqlite3
  defdelegate close(connection), to: Esqlite3
  defdelegate close(connection, timeout), to: Esqlite3
  defdelegate fetchone(statement), to: Esqlite3
  defdelegate fetchall(statement), to: Esqlite3
  defdelegate q(sql, connection), to: Esqlite3
  defdelegate q(sql, args, connection), to: Esqlite3
  defdelegate map(f, sql, connection), to: Esqlite3
  defdelegate foreach(f, sql, connection), to: Esqlite3
end
