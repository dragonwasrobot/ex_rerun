# Changelog

## v0.1.0

### Added

- Support for monitoring Elixir and other source files and running mix tasks on
  code modification changes using the following configuration parameters:

```elixir
config :ex_rerun,
  scan_interval: 3000,
  silent: false,
  elm: true,
  test: false,
  escript: false,
  paths: ["lib", "priv", "web"],
  file_types: [".elm", ".ex", ".exs", ".eex", ".json"]
```

where:

- `scan_interval` specifies the number of ms to wait between rerun checks,
- `silent` toggles whether to print every time `ex_rerun` recompiles,
- `elm` toggles whether to run the elm compilation task on recompile, requires
  [elm_compile](https://hex.pm/packages/elm_compile) is installed as a project
  dependency,
- `test` toggles whether to also run mix test after each recompilation,
- `escript` toggles whether to run the escript compilation task on recompile,
- `paths` lists which folders to monitor, and
- `file_types` lists which files that will trigger a rerun when changed.
