# Getting Started

## Project Setup

To use ExRerun with your projects, edit your `mix.exs` file and add it as a
dependency.

```elixir
defp deps do
  [{:ex_rerun, "~> 0.3", only: :dev}]
end
```

## What is ExRerun

ExRerun is a package that is monitors your Elixir, and other source files, while
you are develop your application and then reruns a set of `mix` tasks whenever a
source file is added, deleted, or changed.

## Configuration

It is possible to configure `ex_rerun` using the following parameters:

> Note: the example below shows the default values.

```elixir
config :ex_rerun,
  scan_interval: 4000,
  silent: false,
  file_types: [".ex", ".exs", ".eex", ".json"],
  paths: ["lib", "priv"],
  ignore_pattern: nil,
  tasks: [:elixir]
```

where:

- `scan_interval` specifies the number of ms to wait between rerun checks,
- `silent` toggles whether to print the output of the `tasks` registered, every
  time `ex_rerun` runs,
- `file_types` lists which file types that will trigger a rerun when changed,
- `paths` lists which folders to monitor,
- `ignore_pattern` specifies a regular expression, e.g. `~r{\.?#(.)}`, matching
  files that should to be ignored even if they have a file type included in
  `file_types`, and
- `tasks` enumerates the mix tasks to run each time a code modification
  occurs, possible built-in values are: `:elixir`, `:test`, `:escript`,
  where
  + `:elixir` recompiles Elixir source code (same as `Mix.Tasks.Compile.Elixir`),
  + `:test` reruns any mix tests in the project (same as `Mix.Tasks.Test`), and
  + `escript` rebuilds a escript file (same as `Mix.Tasks.Escript.Build`).

Furthermore, `tasks` can also include custom mix tasks. For example, the hex
package [elm_compile](https://hex.pm/packages/elm_compile) defines the
`Mix.Tasks.Compile.Elm` task which allows mix to also compile Elm files in a mix
project. An example project config using `ex_rerun` and `elm_compile` might look
like so:

```elixir
config :ex_rerun,
  file_types: [".elm", ".ex", ".exs", ".eex", ".json"],
  paths: ["lib", "priv", "web"],
  ignore_pattern: ~r{\.?#(.)},
  tasks: [:elixir, Mix.Tasks.Compile.Elm]
```

Another example of a custom mix task could be to generate API documentation for
a project based on a set of `RAML` files.
