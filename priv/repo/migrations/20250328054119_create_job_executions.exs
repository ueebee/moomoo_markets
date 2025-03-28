defmodule MoomooMarkets.Repo.Migrations.CreateJobExecutions do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE job_execution_status AS ENUM ('running', 'completed', 'failed', 'retrying')"

    create table(:job_executions) do
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :status, :job_execution_status, null: false
      add :result, :map
      add :error, :text
      add :execution_time, :integer  # ミリ秒単位
      add :memory_usage, :integer    # メモリ使用量（バイト）
      add :retry_count, :integer, default: 0
      add :job_id, references(:jobs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:job_executions, [:job_id])
    create index(:job_executions, [:started_at])
    create index(:job_executions, [:status])
  end

  def down do
    execute "DROP TABLE IF EXISTS job_executions"
    execute "DROP TYPE IF EXISTS job_execution_status"
  end
end
