defmodule MoomooMarkets.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MoomooMarketsWeb.Telemetry,
      MoomooMarkets.Repo,
      {DNSCluster, query: Application.get_env(:moomoo_markets, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MoomooMarkets.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MoomooMarkets.Finch},
      # Start a worker by calling: MoomooMarkets.Worker.start_link(arg)
      # {MoomooMarkets.Worker, arg},
      # Start to serve requests, typically the last entry
      {Oban, Application.fetch_env!(:moomoo_markets, Oban)},
      MoomooMarketsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MoomooMarkets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MoomooMarketsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
