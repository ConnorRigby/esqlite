defmodule Sqlite.Error do
  @moduledoc false

  defexception [:message]

  @typedoc "Various SQLite error."
  @type t :: %Sqlite.Error{
          message: binary
        }

  def message(e), do: e.message
end
