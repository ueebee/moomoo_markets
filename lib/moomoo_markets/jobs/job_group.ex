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
    field :timezone, :string, default: "Asia/Tokyo"

    timestamps()
  end

  # # Required fields for job group creation
  # @required_fields [:name, :data_source_id]

  # # Optional fields for job group creation
  # @optional_fields [:description, :parent_id, :level, :schedule, :status,
  #                  :last_run_at, :next_run_at, :error_count, :max_retries,
  #                  :retry_delay, :schema_module, :parameters_template,
  #                  :is_enabled, :timezone]

  @valid_statuses ["idle", "running", "paused", "error", "completed"]

  @doc false
  def changeset(job_group, attrs) do
    job_group
    |> cast(attrs, [:name, :description, :schema_module, :data_source_id, :schedule, :parameters_template, :is_enabled, :timezone])
    |> validate_required([:name, :schema_module, :data_source_id, :schedule])
    |> validate_level()
    |> validate_schedule()
    |> validate_status()
    |> validate_no_circular_dependency()
    |> validate_timezone()
  end

  defp validate_level(changeset) do
    case get_field(changeset, :parent_id) do
      nil ->
        # If no parent, this should be a top-level group
        put_change(changeset, :level, 1)
      parent_id ->
        # If has parent, level should be parent's level + 1
        parent = MoomooMarkets.Repo.get(__MODULE__, parent_id)
        put_change(changeset, :level, parent.level + 1)
    end
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

  defp validate_timezone(changeset) do
    case get_change(changeset, :timezone) do
      nil -> changeset
      timezone -> validate_timezone_format(changeset, timezone)
    end
  end

  defp validate_timezone_format(changeset, timezone) do
    case DateTime.now(timezone) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, :timezone, "invalid timezone")
    end
  end

  defp validate_status(changeset) do
    case get_field(changeset, :status) do
      status when status in @valid_statuses ->
        changeset
      _ ->
        add_error(changeset, :status, "invalid status")
    end
  end

  defp validate_no_circular_dependency(changeset) do
    case get_field(changeset, :parent_id) do
      nil -> changeset
      parent_id ->
        if would_create_cycle?(changeset, parent_id) do
          add_error(changeset, :parent_id, "would create circular dependency")
        else
          changeset
        end
    end
  end

  defp would_create_cycle?(changeset, parent_id) do
    # Get the current record's ID if it exists
    current_id = case changeset.data do
      %{id: id} -> id
      _ -> nil
    end

    # Check if the parent is a child of the current record
    if current_id do
      MoomooMarkets.Repo.get_by(__MODULE__, parent_id: current_id, id: parent_id) != nil
    else
      false
    end
  end

  @doc """
  Returns true if the job group is ready to run based on its schedule and dependencies.
  """
  def ready_to_run?(job_group) do
    current_time = DateTime.utc_now()

    # Check if it's time to run based on schedule
    schedule_ready = case job_group.schedule do
      nil -> true
      schedule -> check_schedule(schedule, current_time)
    end

    # Check if dependencies are satisfied
    dependencies_ready = Enum.all?(job_group.dependencies, fn dep ->
      dep.depends_on.status == "completed"
    end)

    schedule_ready && dependencies_ready
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
    DateTime.utc_now()
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
