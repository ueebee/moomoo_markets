defmodule MoomooMarkets.Repo.Migrations.CreateJobTables do
  use Ecto.Migration

  def change do
    create table(:job_groups) do
      add :name, :string, null: false
      add :description, :text
      add :data_source, :string, null: false
      add :parent_id, references(:job_groups, on_delete: :nilify_all)
      add :level, :integer, null: false, default: 1
      add :schedule, :map
      add :status, :string, null: false, default: "idle"
      add :last_run_at, :utc_datetime
      add :next_run_at, :utc_datetime
      add :error_count, :integer, default: 0
      add :max_retries, :integer, default: 3
      add :retry_delay, :integer, default: 300  # 5 minutes in seconds

      timestamps()
    end

    create table(:job_group_dependencies) do
      add :job_group_id, references(:job_groups, on_delete: :delete_all), null: false
      add :depends_on_id, references(:job_groups, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:jobs) do
      add :name, :string, null: false
      add :description, :text
      add :parameters, :map, null: false
      add :status, :string, null: false, default: "idle"
      add :last_run_at, :utc_datetime
      add :next_run_at, :utc_datetime
      add :error_count, :integer, default: 0
      add :max_retries, :integer, default: 3
      add :retry_delay, :integer, default: 300  # 5 minutes in seconds
      add :last_error, :text
      add :result, :map
      add :job_group_id, references(:job_groups, on_delete: :delete_all), null: false

      timestamps()
    end

    # Indexes
    create index(:job_groups, [:parent_id])
    create index(:job_groups, [:status])
    create index(:job_groups, [:data_source])

    create index(:job_group_dependencies, [:job_group_id])
    create index(:job_group_dependencies, [:depends_on_id])
    create unique_index(:job_group_dependencies, [:job_group_id, :depends_on_id])

    create index(:jobs, [:job_group_id])
    create index(:jobs, [:status])
  end
end
