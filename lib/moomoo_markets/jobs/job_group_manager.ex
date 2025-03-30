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
  alias Oban.Job

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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
  def init(_opts) do
    schedule_check()
    {:ok, :checked} = check_job_groups()
    {:ok, %{}}
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
    schedule_check()
    {:ok, :checked} = check_job_groups()
    {:noreply, state}
  end

  # Private functions

  defp get_job_group(id) do
    Logger.debug("Fetching job group with id: #{inspect(id)}")
    Logger.debug("Current process: #{inspect(self())}")
    Logger.debug("Repo: #{inspect(Repo)}")

    case Repo.get(JobGroup, id) do
      nil ->
        Logger.debug("Job group not found for id: #{inspect(id)}")
        {:error, :not_found}

      job_group ->
        Logger.debug("Found job group: #{inspect(job_group)}")
        {:ok, job_group}
    end
  end

  # defp create_jobs(job_group) do
  #   # パラメータテンプレートからジョブを作成
  #   case job_group.parameters_template do
  #     nil ->
  #       # テンプレートがない場合は単一のジョブを作成
  #       create_single_job(job_group, %{})
  #     template ->
  #       # テンプレートに基づいて複数のジョブを作成
  #       create_jobs_from_template(job_group, template)
  #   end
  # end
  defp create_jobs(job_group) do
    case job_group.parameters_template do
      nil ->
        # テンプレートがない場合でもリストで包む
        case create_single_job(job_group, %{}) do
          {:ok, job} -> {:ok, [job]}
          error -> error
        end

      template ->
        create_jobs_from_template(job_group, template)
    end
  end

  defp create_single_job(job_group, parameters) do
    %{
      "job_group_id" => to_string(job_group.id),
      "parameters" => parameters
    }
    |> DataFetchWorker.new()
    |> Oban.insert()
  end

  # defp create_jobs_from_template(job_group, template) do
  #   # テンプレートからジョブを作成するロジック
  #   # 例: 複数の銘柄コードに対してジョブを作成
  #   case template do
  #     %{"codes" => codes} when is_list(codes) ->
  #       Enum.reduce_while(codes, {:ok, []}, fn code, {:ok, acc} ->
  #         case create_single_job(job_group, Map.put(template, "code", code)) do
  #           {:ok, job} -> {:cont, {:ok, [job | acc]}}
  #           {:error, reason} -> {:halt, {:error, reason}}
  #         end
  #       end)

  #     _ ->
  #       create_single_job(job_group, template)
  #   end
  # end
  defp create_jobs_from_template(job_group, template) do
    case template do
      %{"codes" => codes} when is_list(codes) ->
        Enum.reduce_while(codes, {:ok, []}, fn code, {:ok, acc} ->
          case create_single_job(job_group, Map.put(template, "code", code)) do
            {:ok, job} -> {:cont, {:ok, [job | acc]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _ ->
        # 👇 ここを修正
        case create_single_job(job_group, template) do
          {:ok, job} -> {:ok, [job]}
          error -> error
        end
    end
  end

  defp update_job_schedules(job_group) do
    next_run = calculate_next_run(job_group.schedule)

    if next_run do
      from(j in Job,
        where: fragment("?->>'job_group_id' = ?", j.args, ^to_string(job_group.id))
      )
      |> Repo.update_all(set: [scheduled_at: DateTime.add(DateTime.utc_now(), next_run, :second)])
      |> case do
        {n, _} -> {:ok, n}
        error -> {:error, error}
      end
    else
      {:error, :invalid_schedule}
    end
  end

  defp resume_jobs(job_group) do
    from(j in Job,
      where: fragment("?->>'job_group_id' = ?", j.args, ^to_string(job_group.id))
    )
    |> Repo.update_all(set: [state: "available"])
    |> case do
      {n, _} -> {:ok, n}
      error -> {:error, error}
    end
  end

  defp pause_jobs(job_group) do
    from(j in Job,
      where: fragment("?->>'job_group_id' = ?", j.args, ^to_string(job_group.id))
    )
    |> Repo.update_all(set: [state: "scheduled"])
    |> case do
      {n, _} -> {:ok, n}
      error -> {:error, error}
    end
  end

  defp check_job_groups do
    JobGroup
    |> Repo.all()
    |> Enum.each(&schedule_job_group/1)

    {:ok, :checked}
  end

  defp schedule_job_group(%JobGroup{is_enabled: true} = job_group) do
    next_run = calculate_next_run(job_group.schedule)

    if next_run do
      %{
        worker: MoomooMarkets.Workers.DataFetchWorker,
        args: %{
          "job_group_id" => to_string(job_group.id),
          "parameters" => job_group.parameters_template
        },
        schedule_in: next_run
      }
      |> Oban.insert()
    end
  end

  defp schedule_job_group(_), do: nil

  def calculate_next_run(schedule) do
    case Crontab.CronExpression.Parser.parse(schedule) do
      {:ok, cron_expression} ->
        now = DateTime.utc_now() |> DateTime.to_naive()

        case Crontab.Scheduler.get_next_run_date(cron_expression, now) do
          {:ok, next_run} ->
            NaiveDateTime.diff(next_run, now, :second)

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check_job_groups, :timer.minutes(1))
  end
end
