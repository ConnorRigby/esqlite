defmodule Sqlite.Error do
  @moduledoc false

  defexception [:message]

  @typedoc "Various SQLite error."
  @type t :: %Sqlite.Error{}

  def exception(%{reason: message}) do
    %Sqlite.Error{message: message}
  end

  def message(e) do
    e.message
  end
end
