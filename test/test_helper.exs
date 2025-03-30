ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MoomooMarkets.Repo, :manual)

# モックAPI起動
{:ok, _pid} = Plug.Cowboy.http(MockJQuants.Server, [], port: 4444)
