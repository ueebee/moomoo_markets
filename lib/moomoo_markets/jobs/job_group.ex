defmodule MoomooMarkets.Jobs.JobGroup do
  @moduledoc """
  JobGroup represents a group of related jobs that can be organized in a hierarchical structure.
  Each JobGroup can have child JobGroups and/or direct jobs.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias MoomooMarkets.Repo

  schema "job_groups" do
    field :name, :string
    field :description, :string
    field :schema_module, :string
    field :data_source_id, :integer
    field :schedule, :string
    field :parameters_template, :map
    field :is_enabled, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(job_group, attrs) do
    job_group
    |> cast(attrs, [:name, :description, :schema_module, :data_source_id, :schedule, :parameters_template, :is_enabled])
    |> validate_required([:name, :schema_module, :data_source_id, :schedule])
    |> validate_schedule()
  end

  defp validate_schedule(changeset) do
    case get_change(changeset, :schedule) do
      nil -> changeset
      schedule -> validate_schedule_format(changeset, schedule)
    end
  end

  defp validate_schedule_format(changeset, schedule) do
    case Crontab.CronExpression.Parser.parse(schedule) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, :schedule, "invalid cron expression")
    end
  end

  @doc """
  Returns true if the job group is ready to run based on its schedule.
  """
  def ready_to_run?(job_group) do
    current_time = DateTime.utc_now()

    # Check if it's time to run based on schedule
    case job_group.schedule do
      nil -> true
      schedule -> check_schedule(schedule, current_time)
    end
  end

  @doc """
  Returns the next run time based on the schedule.
  """
  def calculate_next_run(job_group) do
    case job_group.schedule do
      nil -> nil
      schedule -> calculate_next_run_from_schedule(schedule)
    end
  end

  # Private helper functions

  defp check_schedule(schedule, current_time) do
    case schedule["type"] do
      "cron" -> check_cron_schedule(schedule, current_time)
      "interval" -> check_interval_schedule(schedule, current_time)
      _ -> false
    end
  end

  defp check_cron_schedule(_schedule, _current_time) do
    true
  end

  defp check_interval_schedule(_schedule, _current_time) do
    true
  end

  defp calculate_next_run_from_schedule(_schedule) do
    DateTime.utc_now() |> DateTime.add(3600)  # 1時間後に設定
  end

  def update_schedule(job_group, schedule) do
    job_group
    |> change(%{schedule: schedule})
    |> validate_schedule()
    |> Repo.update()
  end

  def set_enabled(job_group, enabled) do
    job_group
    |> change(%{is_enabled: enabled})
    |> Repo.update()
  end
end
