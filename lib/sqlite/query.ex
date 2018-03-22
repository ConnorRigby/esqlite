defmodule Sqlite.Query do
  @moduledoc "This module handles creation of SQL queries."

  defstruct [
    :statement,
    :column_types,
    :column_names,
    :sql
  ]

  @typedoc "Sqlite Query for execution."
  @type t :: %__MODULE__{
          statement: Esqlite3.prepared_statement(),
          sql: iodata,
          column_names: [iodata] | nil,
          column_types: [atom] | nil
        }

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{statement: {:statement, ref, _}}, _) when is_reference(ref) do
      String.replace(inspect(ref), "Reference", "Statement")
    end

    def inspect(_, _), do: exit("Tried to inspect empty query!")
  end
end
