defmodule Esqlite3 do
  @moduledoc """
  I ported some erlang. Probably don't use this.
  """

  require Logger

  @default_timeout Application.get_env(:esqlite, :default_timeout, 5000)

  @type connection :: {:ok, connection, reference, term}
  @type filename :: Path.t()

  @type sql :: any
  @type error_message :: any
  @type prepared_statement :: any
  @type value_list :: any

  @doc "Opens a sqlite3 database mentioned in Filename."
  @spec open(filename) :: {:ok, connection} | {:error, term}
  def open(filename), do: open(filename, @default_timeout)

  @doc "Opens a sqlite3 database mentioned in Filename."
  @spec open(filename, timeout) :: {:ok, connection} | {:error, term}
  def open(filename, timeout) do
    filename = to_charlist(filename)

    with {:ok, connection} <- Esqlite3Nif.start(),
         ref when is_reference(ref) <- make_ref(),
         :ok <- Esqlite3Nif.open(connection, ref, self(), filename),
         :ok <- receive_answer(ref, timeout) do
      {:ok, {:connection, make_ref(), connection}}
    else
      {:error, _} = err -> err
    end
  end

  @doc "Execute Sql statement, returns the number of affected rows."
  @spec exec(sql, connection) :: integer | {:error, error_message}
  def exec(sql, connection), do: exec(sql, connection, @default_timeout)

  @doc "Execute Sql statement, returns the number of affected rows."
  @spec exec(sql, connection, timeout) :: integer | {:error, error_message}
  def exec(sql, connection, timeout)

  def exec(sql, {:connection, _ref, connection}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.exec(connection, ref, self(), sql)
    receive_answer(ref, timeout)
  end

  def exec(sql, params, connection), do: exec(sql, params, connection, @default_timeout)

  def exec(sql, params, connection, timeout) when is_list(params) do
    {:ok, statement} = prepare(sql, connection, timeout)
    bind(statement, params)
    step(statement, timeout)
  end

  @doc "Return the number of affected rows of last statement."
  @spec changes(connection) :: integer | {:error, error_message}
  def changes(connection), do: changes(connection, @default_timeout)

  @doc "Return the number of affected rows of last statement."
  @spec changes(connection, timeout) :: integer | {:error, error_message}
  def changes(connection, timeout)

  def changes({:connection, _ref, connection}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.changes(connection, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Insert records, returns the last rowid."
  @spec insert(sql, connection) :: {:ok, integer} | {:error, error_message}
  def insert(sql, connection), do: insert(sql, connection, @default_timeout)

  @doc "Insert records, returns the last rowid."
  @spec insert(sql, connection, timeout) :: {:ok, integer} | {:error, error_message}
  def insert(sql, connection, timeout)

  def insert(sql, {:connection, _ref, connection}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.insert(connection, ref, self(), sql)
    receive_answer(ref, timeout)
  end

  @doc "Prepare a statement"
  @spec prepare(sql, connection) :: {:ok, prepared_statement} | {:error, error_message}
  def prepare(sql, connection), do: prepare(sql, connection, @default_timeout)

  @doc "Prepare a statement"
  @spec prepare(sql, connection, timeout) :: {:ok, prepared_statement} | {:error, error_message}
  def prepare(sql, connection, timeout)

  def prepare(sql, {:connection, _ref, connection} = c, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.prepare(connection, ref, self(), sql)

    case receive_answer(ref, timeout) do
      {:ok, prepared_statement} -> {:ok, {:statement, prepared_statement, c}}
      err -> err
    end
  end

  @doc "Step into a prepared statement."
  @spec step(prepared_statement) :: {:ok, any} | {:error, term}
  def step(prepared_statement), do: step(prepared_statement, @default_timeout)

  @doc "Step into a prepared statement."
  @spec step(prepared_statement, timeout) :: {:ok, any} | {:error, term}
  def step(prepared_statement, timeout)

  def step({:statement, prepared_statement, {:connection, _ref, connection}}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.step(connection, prepared_statement, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Reset the prepared statement back to its initial state."
  @spec reset(prepared_statement) :: :ok | {:error, error_message}
  def reset(prepared_statement), do: reset(prepared_statement, @default_timeout)

  @doc "Reset the prepared statement back to its initial state."
  @spec reset(prepared_statement, timeout) :: :ok | {:error, error_message}
  def reset(prepared_statement, timeout)

  def reset({:statement, prepared_statement, {:connection, _ref, connection}}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.reset(connection, prepared_statement, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Bind values to prepared statements"
  @spec bind(prepared_statement, value_list) :: :ok | {:error, error_message}
  def bind(prepared_statement, args), do: bind(prepared_statement, args, @default_timeout)

  @doc "Bind values to prepared statements"
  @spec bind(prepared_statement, value_list, timeout) :: :ok | {:error, error_message}
  def bind(prepared_statement, args, timeout)

  def bind({:statement, prepared_statement, {:connection, _ref, connection}}, args, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.bind(connection, prepared_statement, ref, self(), args)
    receive_answer(ref, timeout)
  end

  @doc "Return the column names of the prepared statement."
  @spec column_names(prepared_statement) :: [atom] | {:error, error_message}
  def column_names(prepared_statement), do: column_names(prepared_statement, @default_timeout)

  @doc "Return the column names of the prepared statement."
  @spec column_names(prepared_statement, timeout) :: [atom] | {:error, error_message}
  def column_names(prepared_statement, timeout)

  def column_names({:statement, prepared_statement, {:connection, _ref, connection}}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.column_names(connection, prepared_statement, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Return the column types of the prepared statement."
  @spec column_types(prepared_statement) :: [atom] | {:error, error_message}
  def column_types(prepared_statement), do: column_types(prepared_statement, @default_timeout)

  @doc "Return the column types of the prepared statement."
  @spec column_types(prepared_statement) :: [atom] | {:error, error_message}
  def column_types(prepared_statement, timeout)

  def column_types({:statement, prepared_statement, {:connection, _ref, connection}}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.column_types(connection, prepared_statement, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Close the database"
  @spec close(connection) :: :ok | {:error, error_message}
  def close(connection), do: close(connection, @default_timeout)

  @doc "Close the database"
  @spec close(connection) :: :ok | {:error, error_message}
  def close(connection, timeout)

  def close({:connection, _ref, connection}, timeout) do
    ref = make_ref()
    :ok = Esqlite3Nif.close(connection, ref, self())
    receive_answer(ref, timeout)
  end

  @doc "Execute a sql statement, returns a list with tuples."
  def q(sql, connection), do: q(sql, [], connection)

  def q(sql, [], connection) do
    case prepare(sql, connection) do
      {:ok, statement} -> fetchall(statement)
      {:error, _} = err -> throw(err)
    end
  end

  def q(sql, args, connection) do
    case prepare(sql, connection) do
      {:ok, statement} ->
        :ok = bind(statement, args)
        fetchall(statement)

      {:error, _} = err ->
        throw(err)
    end
  end

  def map(f, sql, connection) do
    case prepare(sql, connection) do
      {:ok, statement} -> map_s(f, statement)
      {:error, _} = err -> throw(err)
    end
  end

  def map_s(f, statement) when is_function(f, 1) do
    case try_step(statement, 0) do
      :"$done" -> []
      {:error, _} = e -> f.(e)
      {:row, row} -> [f.(row) | map_s(f, statement)]
    end
  end

  def map_s(f, statement) when is_function(f, 2) do
    column_names = column_names(statement)

    case try_step(statement, 0) do
      :"$done" -> []
      {:error, _} = e -> f.([], e)
      {:row, row} -> [f.(column_names, row) | map_s(f, statement)]
    end
  end

  def foreach(f, sql, connection) do
    case prepare(sql, connection) do
      {:ok, statement} -> foreach_s(f, statement)
      {:error, _} = err -> throw(err)
    end
  end

  def foreach_s(f, statement) when is_function(f, 1) do
    case try_step(statement, 0) do
      :"$done" ->
        :ok

      {:error, _} = e ->
        f.(e)

      {:row, row} ->
        f.(row)
        foreach_s(f, statement)
    end
  end

  def foreach_s(f, statement) do
    column_names = column_names(statement)

    case try_step(statement, 0) do
      :"$done" ->
        :ok

      {:error, _} = e ->
        f.([], e)

      {:row, row} ->
        f.(column_names, row)
        foreach_s(f, statement)
    end
  end

  def fetchone(statement) do
    case try_step(statement, 0) do
      :"$done" -> :ok
      {:error, _} = e -> e
      {:row, row} -> row
    end
  end

  def fetchall(statement) do
    case try_step(statement, 0) do
      :"$done" ->
        []

      {:error, _} = e ->
        e

      {:row, row} ->
        case fetchall(statement) do
          {:error, _} = e -> e
          rest -> [row | rest]
        end
    end
  end

  def try_step(statement, tries)

  def try_step(_statement, tries) when tries > 5, do: throw(:too_many_tries)

  def try_step(statement, tries) do
    case step(statement) do
      :"$busy" ->
        :timer.sleep(100 * tries)
        try_step(statement, tries + 1)

      other ->
        other
    end
  end

  defp receive_answer(ref, timeout) when is_reference(ref) and is_integer(timeout) do
    start = :os.timestamp()

    receive do
      {:esqlite3, ^ref, resp} ->
        resp

      {:esqlite3, _ref, _resp} = stale ->
        Logger.warn("Ignoring stale answer: #{inspect(stale)}")
        passed_mics = :timer.now_diff(:os.timestamp(), start) |> div(1000)

        new_timeout =
          case timeout - passed_mics do
            passed when passed < 0 -> 0
            to -> to
          end

        receive_answer(ref, new_timeout)
    after
      timeout -> throw({:error, :timeout, ref})
    end
  end
end

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
