defmodule MoomooMarkets.Repo.Migrations.CreateJobGroups do
  use Ecto.Migration

  def change do
    create table(:job_groups) do
      add :name, :string, null: false
      add :description, :text
      add :schema_module, :string, null: false
      add :schedule, :string
      add :parameters_template, :map
      add :is_enabled, :boolean, default: true, null: false
      add :data_source_id, references(:data_sources, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:job_groups, [:data_source_id])
    create index(:job_groups, [:schema_module])
    create index(:job_groups, [:is_enabled])
  end
end
