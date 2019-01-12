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
    run_elm: Application.get_env(:ex_rerun, :elm, false),
    run_test: Application.get_env(:ex_rerun, :test, false),
    run_escript: Application.get_env(:ex_rerun, :escript, false)
  ]

  use GenServer

  @spec init([String.t()]) :: {:ok, [String.t()]}
  def init(args) do
    {:ok, args}
  end

  @spec start_link :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  def start_link do
    IO.puts("ex_rerun started")
    Process.send_after(__MODULE__, :poll_and_reload, @config[:scan_interval])
    GenServer.start_link(__MODULE__, %{}, name: ExRerun.Worker)
  end

  @type file_mtime :: {Path.t(), :calendar.datetime()}

  @spec handle_info(:poll_and_reload, :calendar.datetime()) :: {:noreply, term}
  def handle_info(:poll_and_reload, old_mtime) do
    all_mtimes =
      @config[:paths]
      |> Enum.map(fn path -> get_dir_mtimes(path) end)
      |> Enum.concat()
      |> Enum.sort_by(fn {_, mtime} -> mtime end)
      |> Enum.reverse()

    {_, new_mtime} =
      all_mtimes
      |> List.first()

    if new_mtime > old_mtime do
      files_changed =
        all_mtimes
        |> Enum.filter(fn {_, mtime} -> mtime > old_mtime end)
        |> Enum.map(fn {filename, _} -> filename end)

      IO.puts("\nFiles changed:")
      files_changed |> Enum.each(fn filename -> IO.puts(filename) end)

      rerun_tasks()
    end

    Process.send_after(__MODULE__, :poll_and_reload, @config[:scan_interval])
    {:noreply, new_mtime}
  end

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
  defp get_files_mtimes(files, acc_files_mtimes, cwd)

  defp get_files_mtimes([], acc_files_mtimes, _cwd) do
    acc_files_mtimes
    |> Enum.filter(fn file_mtime -> file_mtime != nil end)
  end

  defp get_files_mtimes([filename | tail], acc_files_mtimes, cwd) do
    file_path = Path.join(cwd, filename)

    files_mtimes =
      case File.dir?(file_path) do
        true ->
          get_dir_mtimes(file_path)

        false ->
          if has_relevant_filetype(filename) do
            mtime = File.stat!(file_path).mtime
            [{file_path, mtime}]
          else
            []
          end
      end

    get_files_mtimes(tail, files_mtimes ++ acc_files_mtimes, cwd)
  end

  @spec has_relevant_filetype(Path.t()) :: boolean
  defp has_relevant_filetype(filename) do
    @config[:file_types]
    |> Enum.any?(fn file_type -> String.ends_with?(filename, file_type) end)
  end

  @spec rerun_tasks :: :ok
  def rerun_tasks do
    if @config[:silent] == true do
      ExUnit.CaptureIO.capture_io(&compile_elixir/0)

      if @config[:run_elm] == true do
        ExUnit.CaptureIO.capture_io(&compile_elm/0)
      end

      if @config[:run_test] == true do
        ExUnit.CaptureIO.capture_io(&test_elixir/0)
      end

      if @config[:run_escript] == true do
        ExUnit.CaptureIO.capture_io(&compile_escript/0)
      end
    else
      compile_elixir()

      if @config[:run_elm] == true do
        compile_elm()
      end

      if @config[:run_test] == true do
        test_elixir()
      end

      if @config[:run_escript] == true do
        compile_escript()
      end
    end

    :ok
  end

  @spec compile_elm :: :ok | {:error, [String.t()]} | nil
  defp compile_elm do
    if Code.ensure_loaded?(Mix.Tasks.Compile.Elm) do
      Mix.Tasks.Compile.Elm.run([])
    else
      IO.puts("Config value 'elm' was set to 'true but could not find 'Mix.Tasks.Compile.Elm'")
      nil
    end
  end

  @spec compile_elixir :: :ok | {:error, [String.t()]}
  defp compile_elixir do
    Mix.Tasks.Compile.Elixir.run(["--ignore-module-conflict"])
  end

  @spec compile_escript :: :ok | {:error, [String.t()]}
  defp compile_escript do
    Mix.Tasks.Escript.Build.run([])
  end

  @spec test_elixir :: :ok | {:error, [String.t()]}
  defp test_elixir do
    Mix.Tasks.Test.run([])
  end
end
