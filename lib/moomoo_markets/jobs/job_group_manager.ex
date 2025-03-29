defmodule MoomooMarkets.Jobs.JobGroupManager do
  @moduledoc """
  Manages job groups and their associated jobs.
  Handles job creation, scheduling, and monitoring.
  """

  use GenServer
  require Logger
  import Ecto.Query
  alias MoomooMarkets.Jobs.JobGroup
  alias MoomooMarkets.Workers.DataFetchWorker
  alias MoomooMarkets.Repo
  alias Oban

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def create_jobs_for_group(group_id) do
    GenServer.call(__MODULE__, {:create_jobs_for_group, group_id})
  end

  def update_group_schedule(group_id, schedule) do
    GenServer.call(__MODULE__, {:update_group_schedule, group_id, schedule})
  end

  def enable_group(group_id) do
    GenServer.call(__MODULE__, {:enable_group, group_id})
  end

  def disable_group(group_id) do
    GenServer.call(__MODULE__, {:disable_group, group_id})
  end

  # Server Callbacks

  @impl true
  def init(_) do
    schedule_work()
    {:ok, %{
      job_groups: %{},
      active_jobs: %{}
    }}
  end

  @impl true
  def handle_call({:create_jobs_for_group, group_id}, _from, state) do
    case get_job_group(group_id) do
      {:ok, job_group} ->
        case create_jobs(job_group) do
          {:ok, jobs} ->
            {:reply, {:ok, jobs}, state}
          {:error, reason} ->
            Logger.error("Failed to create jobs for group #{group_id}: #{inspect(reason)}")
            {:reply, {:error, reason}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:update_group_schedule, group_id, schedule}, _from, state) do
    case get_job_group(group_id) do
      {:ok, job_group} ->
        case JobGroup.update_schedule(job_group, schedule) do
          {:ok, updated_group} ->
            case update_job_schedules(updated_group) do
              {:ok, _} -> {:reply, {:ok, updated_group}, state}
              {:error, reason} -> {:reply, {:error, reason}, state}
            end
          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:enable_group, group_id}, _from, state) do
    case get_job_group(group_id) do
      {:ok, job_group} ->
        case JobGroup.set_enabled(job_group, true) do
          {:ok, updated_group} ->
            case resume_jobs(updated_group) do
              {:ok, _} -> {:reply, {:ok, updated_group}, state}
              {:error, reason} -> {:reply, {:error, reason}, state}
            end
          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:disable_group, group_id}, _from, state) do
    case get_job_group(group_id) do
      {:ok, job_group} ->
        case JobGroup.set_enabled(job_group, false) do
          {:ok, updated_group} ->
            case pause_jobs(updated_group) do
              {:ok, _} -> {:reply, {:ok, updated_group}, state}
              {:error, reason} -> {:reply, {:error, reason}, state}
            end
          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(:check_job_groups, state) do
    case check_job_groups() do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.error("Failed to check job groups: #{inspect(reason)}")
    end
    schedule_work()  # Schedule next check
    {:noreply, state}
  end

  # Private functions

  defp get_job_group(id) do
    case Repo.get(JobGroup, id) do
      nil -> {:error, :not_found}
      job_group -> {:ok, job_group}
    end
  end

  defp create_jobs(job_group) do
    # パラメータテンプレートからジョブを作成
    case job_group.parameters_template do
      nil ->
        # テンプレートがない場合は単一のジョブを作成
        create_single_job(job_group, %{})
      template ->
        # テンプレートに基づいて複数のジョブを作成
        create_jobs_from_template(job_group, template)
    end
  end

  defp create_single_job(job_group, parameters) do
    %{
      job_group_id: job_group.id,
      parameters: parameters
    }
    |> DataFetchWorker.new()
    |> Oban.insert()
  end

  defp create_jobs_from_template(job_group, template) do
    # テンプレートからジョブを作成するロジック
    # 例: 複数の銘柄コードに対してジョブを作成
    case template do
      %{"codes" => codes} when is_list(codes) ->
        Enum.reduce_while(codes, {:ok, []}, fn code, {:ok, acc} ->
          case create_single_job(job_group, Map.put(template, "code", code)) do
            {:ok, job} -> {:cont, {:ok, [job | acc]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
      _ ->
        create_single_job(job_group, template)
    end
  end

  defp update_job_schedules(job_group) do
    # 既存のジョブのスケジュールを更新
    from(j in Oban.Job,
      where: j.args["job_group_id"] == ^job_group.id
    )
    |> Oban.update_all(set: [schedule: job_group.schedule])
    |> case do
      {_n, _jobs} -> {:ok, :updated}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resume_jobs(job_group) do
    # ジョブを再開
    from(j in Oban.Job,
      where: j.args["job_group_id"] == ^job_group.id
    )
    |> Oban.update_all(set: [state: "available"])
    |> case do
      {_n, _jobs} -> {:ok, :resumed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp pause_jobs(job_group) do
    # ジョブを一時停止
    from(j in Oban.Job,
      where: j.args["job_group_id"] == ^job_group.id
    )
    |> Oban.update_all(set: [state: "scheduled"])
    |> case do
      {_n, _jobs} -> {:ok, :paused}
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_job_groups do
    # ジョブグループの状態をチェック
    from(g in JobGroup,
      where: g.is_enabled == true
    )
    |> Repo.all()
    |> Enum.each(fn group ->
      case check_job_group_status(group) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.error("Failed to check job group #{group.id}: #{inspect(reason)}")
      end
    end)
    {:ok, :checked}
  end

  defp check_job_group_status(job_group) do
    query = from(j in Oban.Job, where: j.args["job_group_id"] == ^job_group.id and j.state == "failed")
    failed_count = Repo.aggregate(query, :count)

    if failed_count > 0 do
      Logger.error("Job group #{job_group.id} has #{failed_count} failed jobs")
      # TODO: 通知処理の実装
    end
  end

  defp schedule_work do
    Process.send_after(self(), :check_job_groups, :timer.minutes(1))
  end
end
