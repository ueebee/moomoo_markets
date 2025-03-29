defmodule MoomooMarkets.Repo.Migrations.SetupJobSystem do
  use Ecto.Migration

  def change do
    create table(:job_groups) do
      add :name, :string, null: false
      add :description, :text
      add :schema_module, :string, null: false
      add :data_source_id, references(:data_sources, on_delete: :restrict), null: false
      add :schedule, :string, null: false
      add :parameters_template, :map
      add :is_enabled, :boolean, default: true, null: false
      add :timezone, :string, default: "Asia/Tokyo", null: false

      timestamps()
    end

    create index(:job_groups, [:data_source_id])
    create index(:job_groups, [:schema_module])
    create index(:job_groups, [:is_enabled])
  end
end
