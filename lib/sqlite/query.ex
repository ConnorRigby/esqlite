defmodule Sqlite.Query do
  @moduledoc "This module handles creation of SQL queries."

  defstruct [:name, :statement]

  @typedoc "Sqlite Query for execution."
  @type t :: %__MODULE__{
          name: String.t(),
          statement: iodata
        }
end
