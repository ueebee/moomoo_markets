defmodule MoomooMarkets.Jobs.JobGroup do
  @moduledoc """
  JobGroup represents a group of related jobs that can be organized in a hierarchical structure.
  Each JobGroup can have child JobGroups and/or direct jobs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "job_groups" do
    field :name, :string
    field :description, :string
    field :data_source, :string
    field :level, :integer, default: 1
    field :schedule, :map
    field :status, :string, default: "idle"
    field :last_run_at, :utc_datetime
    field :next_run_at, :utc_datetime
    field :error_count, :integer, default: 0
    field :max_retries, :integer, default: 3
    field :retry_delay, :integer, default: 300  # 5 minutes in seconds

    # Associations
    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :jobs, MoomooMarkets.Jobs.Job
    has_many :dependencies, MoomooMarkets.Jobs.JobGroupDependency, foreign_key: :job_group_id
    has_many :depends_on, MoomooMarkets.Jobs.JobGroupDependency, foreign_key: :depends_on_id

    timestamps()
  end

  @required_fields [:name, :data_source]
  @optional_fields [:description, :parent_id, :level, :schedule, :status,
                   :last_run_at, :next_run_at, :error_count, :max_retries,
                   :retry_delay]

  @valid_statuses ["idle", "running", "paused", "error", "completed"]

  def changeset(job_group, attrs) do
    job_group
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_level()
    |> validate_schedule()
    |> validate_status()
    |> validate_no_circular_dependency()
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
    case get_field(changeset, :schedule) do
      nil -> changeset
      schedule ->
        validate_schedule_format(changeset, schedule)
    end
  end

  defp validate_schedule_format(changeset, schedule) do
    case schedule do
      %{"type" => "cron", "expression" => expression, "timezone" => timezone} ->
        if valid_cron_expression?(expression) and valid_timezone?(timezone) do
          changeset
        else
          add_error(changeset, :schedule, "invalid cron expression or timezone")
        end
      %{"type" => "interval", "seconds" => seconds} when is_integer(seconds) and seconds > 0 ->
        changeset
      _ ->
        add_error(changeset, :schedule, "invalid schedule format")
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

  defp valid_cron_expression?(expression) do
    # Basic cron expression validation
    # You might want to use a more robust validation library
    Regex.match?(~r/^(\*|[0-9,\-\*\/]+)\s+(\*|[0-9,\-\*\/]+)\s+(\*|[0-9,\-\*\/]+)\s+(\*|[0-9,\-\*\/]+)\s+(\*|[0-9,\-\*\/]+)$/, expression)
  end

  defp valid_timezone?(timezone) do
    # Check if the timezone exists
    # You might want to use a timezone library
    true  # Placeholder
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

  defp check_cron_schedule(schedule, current_time) do
    # Implement cron expression checking
    # You might want to use a library like Crontab
    true  # Placeholder
  end

  defp check_interval_schedule(schedule, current_time) do
    # Implement interval-based schedule checking
    true  # Placeholder
  end

  defp calculate_next_run_from_schedule(schedule) do
    # Implement next run time calculation based on schedule type
    # You might want to use a library like Crontab for cron expressions
    nil  # Placeholder
  end
end
