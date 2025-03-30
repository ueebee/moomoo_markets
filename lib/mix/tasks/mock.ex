defmodule Mix.Tasks.Mock do
  use Mix.Task
  @shortdoc "Starts the J-Quants API mock server"

  @moduledoc """
  Starts the J-Quants API mock server.

  ## Options
    * `--port` - Port number to listen on (default: 4444)
    * `--host` - Host to bind to (default: "127.0.0.1")
    * `--help` - Shows this help message

  ## Examples
      $ mix mock
      $ mix mock --port 4444
      $ mix mock --host 0.0.0.0
  """

  @switches [
    port: :integer,
    host: :string
  ]

  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    port = Keyword.get(opts, :port, 4444)
    host = Keyword.get(opts, :host, "127.0.0.1")

    IO.puts("\n=== Starting J-Quants API Mock Server ===")
    IO.puts("Host: #{host}")
    IO.puts("Port: #{port}")
    IO.puts("=====================================\n")

    # 必要なアプリケーションを起動
    {:ok, _} = Application.ensure_all_started(:plug)
    {:ok, _} = Application.ensure_all_started(:cowboy)
    {:ok, _} = Application.ensure_all_started(:jason)

    # サーバーを起動
    case Plug.Cowboy.http(MockJQuants.Server, [], port: port) do
      {:ok, _pid} ->
        IO.puts("Mock server started successfully")
        # サーバーを永続的に実行
        Process.sleep(:infinity)
      {:error, reason} ->
        IO.puts("Failed to start mock server: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
