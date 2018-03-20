defmodule Esqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :esqlite,
      version: "0.1.0",
      elixir: "~> 1.6",
      compilers: [:elixir_make] ++ Mix.compilers,
      make_clean: ["clean"],
      make_env: make_env(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"
        }
      _ ->
        %{}
    end
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4.1", runtime: false}
    ]
  end
end
