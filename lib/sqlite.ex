defmodule Sqlite do
  @moduledoc """
  SQLite3 driver for Elixir.
  """

  alias Sqlite.Query

  defmodule Connection do
    @moduledoc false
    defstruct [
      :pid,
      :ref,
      :database
    ]

    @typedoc false
    @type t :: %__MODULE__{
            pid: GenServer.server(),
            ref: reference,
            database: Esqlite3.filename()
          }

    defimpl Inspect, for: __MODULE__ do
      def inspect(%{ref: ref}, _opts) when is_reference(ref) do
        String.replace(inspect(ref), "Reference", "Sqlite3")
      end
    end
  end

  @typedoc "Connection identifier for your Sqlite instance."
  @opaque conn :: Connection.t()

  @doc """
  Start the connection process and connect to sqlite.
  ## Options
    * `:database` -> Databse uri.
  ## Examples
      iex> {:ok, pid} = Sqlite.open(database: "sqlite.db")
      {:ok, #PID<0.69.0>}
      iex> {:ok, pid} = Sqlite.open(database: ":memory:")
      {:ok, #PID<0.69.0>}
  """
  @spec open(Keyword.t(), GenServer.options()) :: {:ok, conn} | {:error, term}
  def open(opts, gen_server_opts \\ []) when is_list(opts) do
    opts = Sqlite.Utils.default_opts(opts)

    case GenServer.start_link(Sqlite.Server, opts, gen_server_opts) do
      {:ok, pid} ->
        conn =
          struct(
            Connection,
            pid: pid,
            database: opts[:database],
            ref: make_ref()
          )

        {:ok, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs an (extended) query and returns the result as `{:ok, %Sqlite.Result{}}`
  or `{:error, %Sqlite.Error{}}` if there was a database error. Parameters can
  be set in the query as `$1` embedded in the query string. Parameters are given
  as a list of elixir values. See the README for information on how Sqlite
  encodes and decodes Elixir values by default. See `Sqlite.Result` for the
  result data.
  ## Examples
      Sqlite.query(conn, "CREATE TABLE posts (id serial, title text)", [])
      Sqlite.query(conn, "INSERT INTO posts (title) VALUES ('my title')", [])
      Sqlite.query(conn, "SELECT title FROM posts", [])
      Sqlite.query(conn, "SELECT id FROM posts WHERE title like $1", ["%my%"])
      Sqlite.query(conn, "COPY posts TO STDOUT", [])
  """
  @spec query(conn, iodata, list, Keyword.t()) ::
          {:ok, Sqlite.Result.t()} | {:error, Sqlite.Error.t()}
  def query(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    opts = opts |> defaults()

    GenServer.call(conn.pid, {:query, query, params, opts}, call_timeout(opts))
    |> case do
      {:ok, %Sqlite.Result{}} = ok -> ok
      {:error, %Sqlite.Error{}} = ok -> ok
      err -> unexpected_response(err, :query)
    end
  end

  @doc """
  Runs an (extended) query and returns the result or raises `Sqlite.Error` if
  there was an error. See `query/3`.
  """
  @spec query!(conn, iodata, list, Keyword.t()) :: Sqlite.Result.t()
  def query!(conn, statement, params, opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Sqlite.Error, %{reason: reason}
    end
  end

  @doc """
  Prepares an (extended) query and returns the result as
  `{:ok, %Sqlite.Query{}}` or `{:error, %Sqlite.Error{}}` if there was an
  error. Parameters can be set in the query as `$1` embedded in the query
  string. To execute the query call `execute/4`. To close the prepared query
  call `close/3`. See `Sqlite.Query` for the query data.

  ## Examples
      Sqlite.prepare(conn, "", "CREATE TABLE posts (id serial, title text)")
  """
  @spec prepare(conn, iodata, iodata, Keyword.t()) ::
          {:ok, Sqlite.Query.t()} | {:error, Sqlite.Error.t()}
  def prepare(conn, name, statement, opts \\ []) do
    query = %Query{name: name, statement: statement}
    opts = opts |> defaults()

    GenServer.call(conn.pid, {:prepare, query, opts}, call_timeout(opts))
    |> case do
      {:ok, %Sqlite.Query{}} = ok -> ok
      {:error, %Sqlite.Error{}} = ok -> ok
      err -> unexpected_response(err, :prepare)
    end
  end

  @doc """
  Prepares an (extended) query and returns the prepared query or raises
  `Sqlite.Error` if there was an error. See `prepare/4`.
  """
  @spec prepare!(conn, iodata, iodata, Keyword.t()) :: Sqlite.Query.t()
  def prepare!(conn, name, statement, opts \\ []) do
    case prepare(conn, name, statement, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Sqlite.Error, %{reason: reason}
    end
  end

  @doc """
  Runs an (extended) prepared query and returns the result as
  `{:ok, %Sqlite.Result{}}` or `{:error, %Sqlite.Error{}}` if there was an
  error. Parameters are given as part of the prepared query, `%Sqlite.Query{}`.
  See the README for information on how Sqlite encodes and decodes Elixir
  values by default. See `Sqlite.Query` for the query data and
  `Sqlite.Result` for the result data.

  ## Examples
      query = Sqlite.prepare!(conn, "", "CREATE TABLE posts (id serial, title text)")
      Sqlite.execute(conn, query, [])
      query = Sqlite.prepare!(conn, "", "SELECT id FROM posts WHERE title like $1")
      Sqlite.execute(conn, query, ["%my%"])
  """
  @spec execute(conn, Sqlite.Query.t(), list, Keyword.t()) ::
          {:ok, Sqlite.Result.t()} | {:error, Sqlite.Error.t()}
  def execute(conn, query, params, opts \\ []) do
    opts = defaults(opts)

    GenServer.call(conn.pid, {:execute, query, params, opts}, call_timeout(opts))
    |> case do
      {:ok, %Sqlite.Result{}} = ok -> ok
      {:error, %Sqlite.Error{}} = ok -> ok
      err -> unexpected_response(err, :execute)
    end
  end

  @doc """
  Runs an (extended) prepared query and returns the result or raises
  `Sqlite.Error` if there was an error. See `execute/4`.
  """
  @spec execute!(conn, Sqlite.Query.t(), list, Keyword.t()) :: Sqlite.Result.t()
  def execute!(conn, query, params, opts \\ []) do
    case execute(conn, query, params, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Sqlite.Error, %{reason: reason}
    end
  end

  @doc """
  Closes the connection to the database.
  """
  @spec close(conn, Keyword.t()) :: :ok | {:error, Sqlite.Error.t()}
  def close(conn, opts \\ []) when is_list(opts) do
    opts = defaults(opts)
    GenServer.call(conn.pid, {:close, opts}, call_timeout(opts))
    |> case do
      :ok -> :ok
      {:error, %Sqlite.Error{}} = ok -> ok
      err -> unexpected_response(err, :close)
    end
  end

  @doc """
  Closes an (extended) prepared query and returns `:ok` or raises
  `Sqlite.Error` if there was an error. See `close/3`.
  """
  @spec close!(conn, Keyword.t()) :: :ok
  def close!(conn, opts \\ []) do
    case close(conn, opts) do
      :ok -> :ok
      {:error, reason} -> raise Sqlite.Error, %{reason: reason}
    end
  end

  @spec call_timeout(Keyword.t()) :: timeout
  defp call_timeout(opts) do
    case Keyword.fetch!(opts, :timeout) do
      number when is_integer(number) -> number + 100
      other -> other
    end
  end

  @spec defaults(Keyword.t()) :: Keyword.t()
  defp defaults(opts) do
    defaults = [
      timeout: Application.get_env(:esqlite, :default_timeout, 5000)
    ]

    Keyword.merge(defaults, opts)
  end

  defp unexpected_response(err, fun) do
    raise "Unexpected response to #{fun}: #{inspect(err)}"
  end
end
