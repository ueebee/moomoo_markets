defmodule MoomooMarkets.Jobs.Job do
  @moduledoc """
  Job represents an individual data fetching task.
  It belongs to a JobGroup and contains the parameters and results of the data fetch.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :name, :string
    field :description, :string
    field :parameters, :map
    field :status, :string, default: "idle"
    field :last_run_at, :utc_datetime
    field :next_run_at, :utc_datetime
    field :error_count, :integer, default: 0
    field :max_retries, :integer, default: 3
    field :retry_delay, :integer, default: 300  # 5 minutes in seconds
    field :last_error, :string
    field :last_result, :map  # 最新の実行結果（キャッシュ用）

    # Associations
    belongs_to :job_group, MoomooMarkets.Jobs.JobGroup
    has_many :executions, MoomooMarkets.Jobs.JobExecution

    timestamps()
  end

  @required_fields [:name, :parameters, :job_group_id]
  @optional_fields [:description, :status, :last_run_at, :next_run_at,
                   :error_count, :max_retries, :retry_delay, :last_error,
                   :last_result]

  @valid_statuses ["idle", "running", "completed", "error", "retrying"]

  def changeset(job, attrs) do
    job
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_status()
    |> validate_parameters()
  end

  defp validate_status(changeset) do
    case get_field(changeset, :status) do
      status when status in @valid_statuses ->
        changeset
      _ ->
        add_error(changeset, :status, "invalid status")
    end
  end

  defp validate_parameters(changeset) do
    case get_field(changeset, :parameters) do
      params when is_map(params) ->
        if map_size(params) > 0 do
          changeset
        else
          add_error(changeset, :parameters, "cannot be empty")
        end
      _ ->
        add_error(changeset, :parameters, "must be a map")
    end
  end

  @doc """
  Returns true if the job is ready to run based on its status and retry count.
  """
  def ready_to_run?(job) do
    job.status == "idle" and job.error_count < job.max_retries
  end

  @doc """
  Updates the job status to running and sets the last_run_at timestamp.
  """
  def start(job) do
    %{job |
      status: "running",
      last_run_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the job status to completed and resets error count.
  """
  def complete(job, result) do
    %{job |
      status: "completed",
      last_result: result,
      error_count: 0
    }
  end

  @doc """
  Updates the job status to error and increments error count.
  """
  def fail(job, error) do
    %{job |
      status: "error",
      last_error: error,
      error_count: job.error_count + 1
    }
  end

  @doc """
  Updates the job status to retrying and sets the next run time.
  """
  def retry(job) do
    next_run = DateTime.add(DateTime.utc_now(), job.retry_delay, :second)

    %{job |
      status: "retrying",
      next_run_at: next_run
    }
  end
end
