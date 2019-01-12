defmodule ExRerun.MixProject do
  use Mix.Project

  @version "0.1.0"
  @elixir_version "~> 1.7"

  def project do
    [
      app: :ex_rerun,
      version: @version,
      elixir: @elixir_version,
      aliases: aliases(),
      description: description(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExRerun, []}
    ]
  end

  defp aliases do
    [build: ["deps.get", "compile"]]
  end

  defp description do
    """
    Recompiles mix project on any change to the project src files.
    """
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    [plt_add_deps: :project]
  end

  defp docs do
    [
      name: "ExRerun",
      formatter_opts: [gfm: true],
      source_ref: @version,
      source_url: "https://github.com/dragonwasrobot/ex_rerun",
      extras: [
        "CHANGELOG.md"
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib/ex_rerun.ex",
        "lib/worker.ex",
        "mix.exs",
        "README.md",
        "LICENSE.md"
      ],
      maintainers: ["Peter Urbak"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/dragonwasrobot/ex_rerun"}
    ]
  end
end
