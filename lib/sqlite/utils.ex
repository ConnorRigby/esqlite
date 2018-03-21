defmodule Sqlite.Utils do
  @moduledoc false

  @spec default_opts(Keyword.t()) :: Keyword.t()
  def default_opts(opts) do
    Keyword.merge([timeout: Application.get_env(:esqlite, :default_timeout, 5000)], opts)
  end
end
