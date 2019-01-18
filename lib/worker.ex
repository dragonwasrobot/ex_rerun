defmodule ExRerun.Worker do
  @moduledoc """
  The main worker of the ExRerun project.
  """

  @config [
    paths: Application.get_env(:ex_rerun, :paths, ["lib", "priv"]),
    file_types:
      Application.get_env(:ex_rerun, :file_types, [
        ".ex",
        ".exs",
        ".eex",
        ".json"
      ]),
    scan_interval: Application.get_env(:ex_rerun, :scan_interval, 4000),
    silent: Application.get_env(:ex_rerun, :silent, false),
    tasks: Application.get_env(:ex_rerun, :tasks, [:elixir])
  ]

  use GenServer
  alias Mix.Tasks.{Compile, Escript, Test}

  @spec init([String.t()]) :: {:ok, [String.t()], integer}
  def init(args) do
    {:ok, args, @config[:scan_interval]}
  end

  @spec start_link :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link do
    IO.puts("ex_rerun started with config:")
    IO.puts("- scan_interval: #{inspect(@config[:scan_interval])}")
    IO.puts("- tasks: #{inspect(@config[:tasks])}")
    GenServer.start_link(__MODULE__, nil, name: ExRerun.Worker)
  end

  @type state :: nil | :calendar.datetime()
  @type file_mtime :: {Path.t(), :calendar.datetime()}

  @spec handle_info(:timeout, state) :: {:noreply, state, integer}
  def handle_info(:timeout, old_mtime) do
    all_mtimes =
      @config[:paths]
      |> Enum.map(fn path -> get_dir_mtimes(path) end)
      |> Enum.concat()
      |> Enum.sort_by(fn {_, mtime} -> mtime end)
      |> Enum.reverse()

    {_, new_mtime} =
      all_mtimes
      |> List.first()

    if old_mtime != nil and new_mtime > old_mtime do
      files_changed =
        all_mtimes
        |> Enum.filter(fn {_, mtime} -> mtime > old_mtime end)
        |> Enum.map(fn {filename, _} -> filename end)

      IO.puts("\nFiles changed:")
      files_changed |> Enum.each(fn filename -> IO.puts(filename) end)

      rerun_tasks()
    end

    {:noreply, new_mtime, @config[:scan_interval]}
  end

  @doc """
  Returns a flatten list of `file_mtime` for all files in directory, `dir`.
  """
  @spec get_dir_mtimes(Path.t()) :: [file_mtime]
  def get_dir_mtimes(dir) do
    case File.ls(dir) do
      {:ok, files} ->
        get_files_mtimes(files, [], dir)

      _ ->
        []
    end
  end

  @spec get_files_mtimes([Path.t()], [file_mtime], Path.t()) :: [file_mtime]
  defp get_files_mtimes(filenames, acc_files_mtimes, cwd)

  defp get_files_mtimes([], acc_files_mtimes, _cwd), do: acc_files_mtimes

  defp get_files_mtimes([filename | filenames], acc_files_mtimes, cwd) do
    file_path = Path.join(cwd, filename)

    files_mtimes =
      if File.dir?(file_path) do
        get_dir_mtimes(file_path)
      else
        if has_relevant_filetype?(filename) do
          case File.stat(file_path) do
            {:ok, file_stat} ->
              [{file_path, file_stat.mtime}]

            {:error, _error} ->
              []
          end
        else
          []
        end
      end

    get_files_mtimes(filenames, files_mtimes ++ acc_files_mtimes, cwd)
  end

  @spec has_relevant_filetype?(Path.t()) :: boolean
  defp has_relevant_filetype?(filename) do
    @config[:file_types]
    |> Enum.any?(fn file_type -> String.ends_with?(filename, file_type) end)
  end

  @spec rerun_tasks :: :ok
  def rerun_tasks do
    @config[:tasks]
    |> Enum.map(&normalize_task_name/1)
    |> Enum.map(&check_if_silent_output/1)
    |> Enum.each(fn task -> task.() end)
  end

  @spec normalize_task_name(atom) :: term
  def normalize_task_name(:elixir),
    do: fn -> Compile.Elixir.run(["--ignore-module-conflict"]) end

  def normalize_task_name(:escript), do: fn -> Escript.Build.run([]) end

  def normalize_task_name(:test), do: fn -> Test.run([]) end

  def normalize_task_name(module_name) do
    fn ->
      if Code.ensure_loaded?(module_name) do
        module_name.run([])
      else
        IO.puts(
          "Mix task `#{module_name}` set to be run by `ex_rerun` " <>
            "but could not be found by `Code.ensure_loaded?`"
        )
      end
    end
  end

  @spec check_if_silent_output(term) :: term
  defp check_if_silent_output(fun) do
    if @config[:silent] == true do
      ExUnit.CaptureIO.capture_io(fun)
    else
      fun
    end
  end
end
