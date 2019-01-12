defmodule ExRerun do
  @moduledoc """
  Recompiles mix project on any change to the project src files.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ExRerun.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: ExRerun.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
