defmodule Esqlite3Nif do
  @moduledoc """
  Interact with the Esqlite3 nif.
  Every function in this module will throw a `:nif_library_not_loaded` error if
  the nif hasn't been compiled/loaded.
  """

  @typep error_tup2 :: {:error, term}

  @typedoc "Database connection Resource. This isn't a true `reference`."
  @opaque connection :: reference

  @typedoc "SQL data."
  @type sql :: iodata

  @typedoc "Statement reference. This isn't a true `reference`."
  @opaque statement :: reference

  @typedoc "Args when using `bind/5`"
  @type bind_arg :: atom | number | iodata

  @typedoc "List of binding args."
  @type bind_args :: [bind_arg]

  @doc "Start a low level thread which will can handle sqlite3 calls."
  @spec start() :: {:ok, connection} | error_tup2
  def start(), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Open the specified sqlite3 database."
  @spec open(connection, reference, pid, Path.t()) :: :ok | error_tup2
  def open(_db, _ref, _dest, _filename), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc """
  Exec the query.
  Sends an asynchronous exec command over the connection and returns
  `:ok` immediately.
  When the statement is executed `dest` will receive message `{ref, answer}`
  with `answer :: integer | {:error, term}`
  """
  @spec exec(connection, reference, pid, sql) :: :ok | error_tup2
  def exec(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc """
  Get the number of affected rows of last statement
  When the statement is executed Dest will receive message {Ref, answer()}
  with `answer :: integer | {:error, term}`
  """
  @spec changes(connection, reference, pid) :: :ok | error_tup2
  def changes(_db, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Prepare a statement."
  @spec prepare(connection, reference, pid, sql) :: :ok | error_tup2
  def prepare(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Step thru a statement."
  @spec step(connection, statement, reference, pid) :: :ok | error_tup2
  def step(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Reset a prepared statement."
  @spec reset(connection, statement, reference, pid) :: :ok | error_tup2
  def reset(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @spec finalize(connection, statement, reference, pid) :: :ok | error_tup2
  def finalize(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Bind paramaters to a prepared statement."
  @spec bind(connection, statement, reference, pid, bind_args) :: :ok | error_tup2
  def bind(_db, _stmt, _ref, _dest, _args), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Retrieve the column names of the prepared statement"
  @spec column_names(connection, statement, reference, pid) :: :ok | error_tup2
  def column_names(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Retrieve the column types of the prepared statement"
  @spec column_types(connection, statement, reference, pid) :: :ok | error_tup2
  def column_types(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Close the connection."
  @spec close(connection, reference, pid) :: :ok | error_tup2
  def close(_db, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)

  @doc "Insert record"
  @spec insert(connection, reference, pid, sql) :: :ok | error_tup2
  def insert(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)

  @on_load :load_nif
  @doc false
  def load_nif do
    require Logger
    nif_file = '#{:code.priv_dir(:esqlite)}/esqlite3_nif'

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> Logger.warn("Failed to load nif: #{inspect(reason)}")
    end
  end
end
