defmodule MoomooMarkets.Repo.Migrations.ModifyDataSourceCredentialsTokenLength do
  use Ecto.Migration

  def change do
    alter table(:data_source_credentials) do
      modify :refresh_token, :text
      modify :id_token, :text
    end
  end
end
