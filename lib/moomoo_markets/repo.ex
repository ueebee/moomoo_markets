defmodule MoomooMarkets.Repo do
  use Ecto.Repo,
    otp_app: :moomoo_markets,
    adapter: Ecto.Adapters.Postgres
end
