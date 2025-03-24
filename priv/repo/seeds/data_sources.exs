alias MoomooMarkets.DataSources.DataSource
alias MoomooMarkets.Repo

# J-Quants API
%DataSource{
  name: "J-Quants API",
  description: "JPX Market Innovation & Research, Inc.が提供する日本市場の金融データAPI",
  provider_type: "jquants",
  is_enabled: true,
  base_url: "https://api.jquants.com/v1",
  api_version: "v1",
  rate_limit_per_minute: 30,
  rate_limit_per_hour: 1000,
  rate_limit_per_day: 10000
}
|> Repo.insert!(
  on_conflict: {:replace_all_except, [:id, :inserted_at]},
  conflict_target: :provider_type
)
