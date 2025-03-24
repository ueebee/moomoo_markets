defmodule MoomooMarkets.Repo.Migrations.CreateDataSourceCredentials do
  use Ecto.Migration

  def change do
    create table(:data_source_credentials) do
      add :encrypted_credentials, :binary, null: false
      add :refresh_token, :string
      add :refresh_token_expired_at, :utc_datetime
      add :id_token, :string
      add :id_token_expired_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :data_source_id, references(:data_sources, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:data_source_credentials, [:user_id])
    create index(:data_source_credentials, [:data_source_id])
    create unique_index(:data_source_credentials, [:user_id, :data_source_id])
  end
end
