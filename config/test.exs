import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :moomoo_markets, MoomooMarkets.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "moomoo_markets_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :moomoo_markets, MoomooMarketsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MUw61uuhvqOteZ82WQbtLkM2mRnsj8MLOO1ixP+xpIZzI3cgnDHZau7vVfw2F4K2",
  server: false

# In test we don't send emails
config :moomoo_markets, MoomooMarkets.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true


config :moomoo_markets, Oban,
  testing: :inline,
  repo: MoomooMarkets.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}, # 7 days
    {Oban.Plugins.Stager, interval: :timer.minutes(1)}
  ],
  queues: [
    default: 10,
    high_priority: 20,
    low_priority: 5
  ]
