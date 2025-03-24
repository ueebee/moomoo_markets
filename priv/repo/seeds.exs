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


# 環境変数からシードユーザーの設定を取得（デフォルト値付き）
seed_user_email = System.get_env("SEED_USER_EMAIL", "test@example.com")
seed_user_password = System.get_env("SEED_USER_PASSWORD", "89#$%aaw*AA666")

# テストユーザーの作成
case Accounts.register_user(%{
  email: seed_user_email,
  password: seed_user_password,
  confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
}) do
  {:ok, user} ->
    IO.puts "Created seed user: #{user.email}"
  {:error, changeset} ->
    IO.puts "Failed to create seed user:"
    IO.inspect(changeset.errors)
    raise "Failed to create seed user"
end
