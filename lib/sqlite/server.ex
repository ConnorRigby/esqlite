defmodule Sqlite.Server do
  @moduledoc "GenServer implementation for Sqlite."
  use GenServer
  alias Sqlite.Query

  defmodule State do
    @moduledoc false
    defstruct [:database, :filename]
    @typedoc false
    @type t :: %__MODULE__{
            database: Esqlite3.connection() | :closed,
            filename: Esqlite3.filename()
          }
  end

  @impl GenServer
  def init(opts) do
    filename = Keyword.fetch!(opts, :database)
    timeout = Keyword.fetch!(opts, :timeout)

    case Esqlite3.open(filename, timeout) do
      {:ok, db} ->
        {:ok, struct(State, database: db, filename: filename)}

      err ->
        {:stop, err}
    end
  end

  @impl GenServer
  def terminate(_, state) do
    unless state.database == :closed do
      :ok = Esqlite3.close(state.database)
    end

    :ok
  end

  @impl GenServer
  def handle_call({:query, sql, params, opts}, _from, state) do
    try do
      with {:ok, %Query{} = q} <- build_query(sql, opts, state.database),
           :ok <- Esqlite3.bind(q.statement, params) do
        r = q.statement |> Esqlite3.fetchall() |> build_result(q, state)
        {:reply, r, state}
      else
        err -> {:reply, error(err, state), state}
      end
    catch
      err -> {:reply, error(err, state), state}
    end
  end

  def handle_call({:release_query, query, opts}, _from, state) do
    try do
      case Esqlite3.reset(query.statement, opts[:timeout]) do
        :ok -> {:reply, :ok, state}
        err -> {:reply, error(err, state), state}
      end
    catch
      err -> {:reply, error(err, state), state}
    end
  end

  def handle_call({:prepare, sql, opts}, _from, state) do
    try do
      case build_query(sql, opts, state.database) do
        {:ok, %Query{} = q} ->
          {:reply, {:ok, q}, state}

        err ->
          {:reply, error(err, state), state}
      end
    catch
      err -> {:reply, error(err, state), state}
    end
  end

  def handle_call({:execute, query, params, opts}, _from, state) do
    try do
      case Esqlite3.bind(query.statement, params, opts[:timeout]) do
        :ok ->
          r = query.statement |> Esqlite3.fetchall() |> build_result(query, state)
          {:reply, r, state}

        err ->
          {:reply, error(err, state), state}
      end
    catch
      err -> {:reply, error(err, state), state}
    end
  end

  def handle_call({:close, opts}, _from, state) do
    case Esqlite3.close(state.database, opts[:timeout]) do
      :ok -> {:stop, :normal, :ok, %{state | database: :closed}}
      {:error, reason} -> {:stop, reason, error(reason, state), state}
    end
  end

  @spec error(any, State.t()) :: {:error, Sqlite.Error.t()}

  defp error({:error, {:sqlite_error, msg}}, _state),
    do: {:error, %Sqlite.Error{message: to_string(msg)}}

  defp error({:error, {:constraint, msg}}, _state),
    do: {:error, %Sqlite.Error{message: to_string(msg)}}

  defp error({:error, msg}, _state) when is_atom(msg),
    do: {:error, %Sqlite.Error{message: to_string(msg)}}

  defp error(reason, _state), do: {:error, %Sqlite.Error{message: reason}}

  @spec build_query(iodata, Keyword.t(), Esqlite3.connection()) ::
          {:ok, Sqlite.Query.t()} | {:error, term}
  defp build_query(sql, opts, database) do
    timeout = opts[:timeout]

    case Esqlite3.prepare(sql, database, timeout) do
      {:ok, statement} ->
        cn = statement |> Esqlite3.column_names(timeout) |> Tuple.to_list()
        ct = statement |> Esqlite3.column_types(timeout) |> Tuple.to_list()
        {:ok, %Sqlite.Query{column_names: cn, column_types: ct, statement: statement, sql: sql}}

      err ->
        err
    end
  end

  @spec build_result(any, Sqlite.Query.t(), State.t()) ::
          {:ok, Sqlite.Result.t()} | {:error, Sqlite.Error.t()}
  defp build_result({:error, _} = err, _q, state), do: error(err, state)

  defp build_result(result, %Query{} = q, _state) when is_list(result) do
    rows = Enum.map(result, &Tuple.to_list(&1))
    num_rows = Enum.count(rows)
    {:ok, %Sqlite.Result{rows: rows, num_rows: num_rows, columns: q.column_names}}
  end
end
