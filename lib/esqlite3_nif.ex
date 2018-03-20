defmodule Esqlite3Nif do
  require Logger
  
  @on_load :load_nif
  @doc false
  def load_nif do
    nif_file = '#{:code.priv_dir(:esqlite)}/esqlite3_nif'
    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> Logger.warn "Failed to load nif: #{inspect reason}"
    end
  end

  def start(), do: :erlang.nif_error(:nif_library_not_loaded)
  def open(_db, _ref, _dest, _filename), do: :erlang.nif_error(:nif_library_not_loaded)
  def exec(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)
  def changes(_db, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def prepare(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)
  def step(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def reset(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def finalize(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def bind(_db, _stmt, _ref, _dest, _args), do: :erlang.nif_error(:nif_library_not_loaded)
  def column_names(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def column_types(_db, _stmt, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def close(_db, _ref, _dest), do: :erlang.nif_error(:nif_library_not_loaded)
  def insert(_db, _ref, _dest, _sql), do: :erlang.nif_error(:nif_library_not_loaded)
end
