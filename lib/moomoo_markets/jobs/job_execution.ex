defmodule MoomooMarkets.Jobs.JobExecution do
  @moduledoc """
  JobExecution represents a single execution of a job.
  It tracks the execution details, results, and any errors that occurred.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias MoomooMarkets.Jobs.Job

  schema "job_executions" do
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :status, Ecto.Enum, values: [:running, :completed, :failed, :retrying]
    field :result, :map
    field :error, :string
    field :execution_time, :integer  # ミリ秒単位
    field :memory_usage, :integer    # メモリ使用量（バイト）
    field :retry_count, :integer, default: 0

    belongs_to :job, Job

    timestamps()
  end

  @required_fields [:started_at, :status, :job_id]
  @optional_fields [:completed_at, :result, :error, :execution_time, :memory_usage, :retry_count]

  def changeset(job_execution, attrs) do
    job_execution
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_timestamps()
  end

  defp validate_timestamps(changeset) do
    started_at = get_field(changeset, :started_at)
    completed_at = get_field(changeset, :completed_at)

    case {started_at, completed_at} do
      {started, completed} when not is_nil(completed) ->
        if DateTime.compare(started, completed) == :gt do
          add_error(changeset, :completed_at, "must be after started_at")
        else
          changeset
        end
      _ ->
        changeset
    end
  end

  @doc """
  Creates a new job execution record with the given job ID.
  """
  def start(job_id) do
    %__MODULE__{
      job_id: job_id,
      started_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: :running
    }
  end

  @doc """
  Updates the job execution record with completion details.
  """
  def complete(job_execution, result) do
    completed_at = DateTime.utc_now() |> DateTime.truncate(:second)
    execution_time = DateTime.diff(completed_at, job_execution.started_at, :millisecond)

    job_execution
    |> changeset(%{
      status: :completed,
      completed_at: completed_at,
      result: result,
      execution_time: execution_time
    })
  end

  @doc """
  Updates the job execution record with error details.
  """
  def fail(job_execution, error) do
    completed_at = DateTime.utc_now() |> DateTime.truncate(:second)
    execution_time = DateTime.diff(completed_at, job_execution.started_at, :millisecond)

    job_execution
    |> changeset(%{
      status: :failed,
      completed_at: completed_at,
      error: error,
      execution_time: execution_time
    })
  end

  @doc """
  Updates the job execution record for retry.
  """
  def retry(job_execution) do
    job_execution
    |> changeset(%{
      status: :running,
      completed_at: nil,
      error: nil,
      execution_time: nil,
      retry_count: job_execution.retry_count + 1
    })
  end
end
