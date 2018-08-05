defmodule Sqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :sqlite,
      version: "1.0.0",
      elixir: "~> 1.6",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_clean: ["clean"],
      make_env: make_env(),
      plt_add_deps: :apps_direct,
      plt_add_apps: [],
      dialyzer: [flags: [:unmatched_returns, :race_conditions, :no_unused]],
      erlc_paths: erlc_paths(Mix.env()),
      test_paths: ["test", "bench"],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        test: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  defp erlc_paths(:test), do: ["erl_test"]
  defp erlc_paths(_), do: []

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
      {:elixir_make, "~> 0.4.2", runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", runtime: false, only: :dev},
      {:excoveralls, "~> 0.9", only: :test, optional: true},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false}
    ]
  end
end
