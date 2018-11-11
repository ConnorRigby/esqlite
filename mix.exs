defmodule Sqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :sqlite,
      version: "1.1.0",
      elixir: "~> 1.4",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_clean: ["clean"],
      make_env: make_env(),
      package: package(),
      description: "Elixir NIF for Sqlite3.",
      plt_add_deps: :apps_direct,
      plt_add_apps: [],
      dialyzer: [flags: [:unmatched_returns, :race_conditions, :no_unused]],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.circls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
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
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", runtime: false, only: :dev},
      {:elixir_make, "~> 0.4.2", runtime: false},
      {:excoveralls, "~> 0.9", only: :test, optional: true},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:inch_ex, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Connor Rigby"],
      licenses: ["Apache2"],
      links: %{
        GitHub: "https://github.com/Sqlite-Ecto/elixir_sqlite",
        source_url: "https://github.com/Sqlite-Ecto/elixir_sqlite"
      },
      files: [
        "lib",
        "c_src/*.[ch]",
        "c_src/sqlite3/*.[ch]",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "Makefile"
      ]
    ]
  end
end
