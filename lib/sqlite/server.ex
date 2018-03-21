defmodule Sqlite.Server do
  @moduledoc "GenServer implementation for Sqlite."
  use GenServer
  # alias Sqlite.{Query, Error, Result}

  defmodule State do
    @moduledoc false
    defstruct [:database, :filename]
    @typedoc false
    @type t :: %__MODULE__{
      database: Esqlite3.connection | :closed,
      filename: Esqlite3.filename,
    }
  end

  @impl GenServer
  def init(opts) do
    filename = Keyword.fetch!(opts, :database)
    timeout = Keyword.fetch!(opts, :timeout)
    case Esqlite3.open(filename, timeout) do
      {:ok, db} ->
        {:ok, struct(State, [database: db, filename: filename])}
      err -> {:stop, err}
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
  def handle_call({:query, query, params, _opts}, _from, state) do
    Esqlite3.q(query.statement, params, state.database) |> IO.inspect
    {:reply, {:error, %Sqlite.Error{message: "Not implemented"}}, state}
  end

  def handle_call({:prepare, query, opts}, _from, state) do
    Esqlite3.prepare(query.statement, state.database, opts[:timeout]) |> IO.inspect
    {:reply, {:error, %Sqlite.Error{message: "Not implemented"}}, state}
  end

  def handle_call({:execute, query, params, opts}, _from, state) do
    Esqlite3.exec(query.statement, params, state.database, opts[:timeout]) |> IO.inspect
    {:reply, {:error, %Sqlite.Error{message: "Not implemented"}}, state}
  end

  def handle_call({:close, _opts}, _from, state) do
    case Esqlite3.close(state.database) do
      :ok -> {:stop, :normal, :ok, %{state | database: :closed}}
      {:error, reason} -> {:stop, reason, error(reason, state), state}
    end
  end

  defp error(reason, _state), do: %Sqlite.Error{message: reason}

end
