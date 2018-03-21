defmodule Sqlite.Result do
  @moduledoc "Results of a Query."

  defstruct [
    :columns,
    :rows,
    :num_rows
  ]

  @type t :: %Sqlite.Result{
          columns: [String.t()],
          rows: [[term] | binary],
          num_rows: integer
        }
end
