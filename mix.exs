defmodule OpEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :op_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      {:bypass, "~> 0.9", only: :test},
      {:distillery, "~> 2.0", runtime: false},
      {:httpoison, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.4"},
      {:ok, "~> 2.0"},
      {:gen_stage, "~> 0.14"},
      {:elastix, git: "https://github.com/werbitzky/elastix.git", branch: "master"}
    ]
  end
end
