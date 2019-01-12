defmodule ExRerun.MixProject do
  use Mix.Project

  @version "1.0.0"
  @elixir_version "~> 1.7"

  def project do
    [
      app: :ex_rerun,
      version: @version,
      elixir: @elixir_version,
      description: description(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExRerun, []}
    ]
  end

  defp description do
    """
    Recompiles mix project on any change to the project src files.
    """
  end

  defp deps, do: []
end
