defmodule MoomooMarkets.Repo.Migrations.CreateDataSources do
  use Ecto.Migration

  def change do
    create table(:data_sources) do
      add :name, :string
      add :description, :text
      add :provider_type, :string
      add :is_enabled, :boolean, default: false, null: false
      add :base_url, :string
      add :api_version, :string
      add :rate_limit_per_minute, :integer
      add :rate_limit_per_hour, :integer
      add :rate_limit_per_day, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:data_sources, [:provider_type])
  end
end
