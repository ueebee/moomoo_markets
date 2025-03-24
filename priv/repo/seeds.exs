# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MoomooMarkets.Repo.insert!(%MoomooMarkets.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# This file is responsible for seeding your database
# with its default values.
#
# The command can be run as:

alias MoomooMarkets.Accounts
alias MoomooMarkets.Repo
alias MoomooMarkets.Accounts.User
alias MoomooMarkets.DataSources.DataSource
alias MoomooMarkets.DataSources.DataSourceCredential
alias MoomooMarkets.Encryption

# 環境変数からシードユーザーの設定を取得（デフォルト値付き）
seed_user_email = System.get_env("SEED_USER_EMAIL", "test@example.com")
seed_user_password = System.get_env("SEED_USER_PASSWORD", "89#$%aaw*AA666")

# テストユーザーの作成
user = case Accounts.register_user(%{
  email: seed_user_email,
  password: seed_user_password
}) do
  {:ok, user} ->
    # ユーザーを直接確認済みにする
    user
    |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update!()
    IO.puts "Created and confirmed seed user: #{user.email}"
    user
  {:error, changeset} ->
    IO.puts "Failed to create seed user:"
    IO.inspect(changeset.errors)
    raise "Failed to create seed user"
end

# Create J-Quants data source
{:ok, jquants} =
  Repo.insert(%DataSource{
    name: "J-Quants API",
    description: "日本取引所グループが提供する金融データAPI",
    provider_type: "jquants",
    is_enabled: true,
    base_url: "https://api.jquants.com/v1",
    api_version: "v1",
    rate_limit_per_minute: 30,
    rate_limit_per_hour: 1000,
    rate_limit_per_day: 10000
  })

# Create J-Quants credentials
credentials = %{
  mailaddress: System.get_env("SEED_JQUANTS_EMAIL"),
  password: System.get_env("SEED_JQUANTS_PASSWORD")
}

encrypted_credentials = credentials
  |> Jason.encode!()
  |> Encryption.encrypt()

Repo.insert(%DataSourceCredential{
  user_id: user.id,
  data_source_id: jquants.id,
  encrypted_credentials: encrypted_credentials
})
