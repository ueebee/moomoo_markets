defmodule MoomooMarkets.Jobs.JobGroupManagerTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.Jobs.{JobGroup, JobGroupManager}
  alias MoomooMarkets.Workers.DataFetchWorker
  alias Oban.Job

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MoomooMarkets.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(MoomooMarkets.Repo, {:shared, self()})

    # Obanを先に起動
    # {:ok, oban_pid} = Oban.start_link(repo: MoomooMarkets.Repo, plugins: [])
    oban_pid = start_supervised!({Oban, repo: MoomooMarkets.Repo, plugins: []})
    # ObanやJobGroupManagerのプロセスにもDB接続を許可
    Ecto.Adapters.SQL.Sandbox.allow(MoomooMarkets.Repo, self(), oban_pid)
    # {:ok, manager_pid} = JobGroupManager.start_link([])
    manager_pid = start_supervised!(JobGroupManager)
    Ecto.Adapters.SQL.Sandbox.allow(MoomooMarkets.Repo, self(), manager_pid)

    seed_data = MoomooMarkets.TestSeedHelper.insert_test_seeds()

    seed_data
  end

  describe "job group management" do
    test "creates jobs for a group", %{data_source: data_source} do

      # テスト用のジョブグループを作成
      job_group_changeset = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: data_source.id,
        schedule: "0 * * * *",
        parameters_template: %{
          "code" => "7203",
          "from" => "2024-01-01",
          "to" => "2024-01-31"
        },
        is_enabled: true
      }

      case Repo.insert(job_group_changeset) do
        {:ok, job_group} ->
          # IO.inspect(job_group, label: "Inserted Job Group")
          assert {:ok, jobs} = JobGroupManager.create_jobs_for_group(job_group.id)
          assert length(jobs) > 0
          assert Enum.all?(jobs, &(&1.worker == "MoomooMarkets.Workers.DataFetchWorker"))
          assert Enum.all?(jobs, &(&1.args["job_group_id"] == to_string(job_group.id)))

        {:error, changeset} ->
          IO.inspect(changeset, label: "Error Changeset")
          flunk("Failed to insert job group: #{inspect(changeset.errors)}")
      end
    end

    test "updates group schedule", %{credential: credential} do
      # テスト用のジョブグループを作成
      {:ok, job_group} = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: credential.data_source_id,
        schedule: "0 * * * *",
        parameters_template: %{
          "code" => "7203",
          "from" => "2024-01-01",
          "to" => "2024-01-31"
        },
        is_enabled: true
      } |> Repo.insert()

      new_schedule = "30 * * * *"
      assert {:ok, updated_group} = JobGroupManager.update_group_schedule(job_group.id, new_schedule)
      assert updated_group.schedule == new_schedule
    end

    test "enables and disables group", %{credential: credential} do
      # テスト用のジョブグループを作成
      {:ok, job_group} = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: credential.data_source_id,
        schedule: "0 * * * *",
        parameters_template: %{
          "code" => "7203",
          "from" => "2024-01-01",
          "to" => "2024-01-31"
        },
        is_enabled: true
      } |> Repo.insert()

      assert {:ok, disabled_group} = JobGroupManager.disable_group(job_group.id)
      assert disabled_group.is_enabled == false

      assert {:ok, enabled_group} = JobGroupManager.enable_group(job_group.id)
      assert enabled_group.is_enabled == true
    end
  end

  describe "job creation" do
    test "creates single job without template", %{credential: credential} do
      # テスト用のジョブグループを作成
      {:ok, job_group} = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: credential.data_source_id,
        schedule: "0 * * * *",
        parameters_template: nil,
        is_enabled: true
      } |> Repo.insert()

      assert {:ok, jobs} = JobGroupManager.create_jobs_for_group(job_group.id)
      assert length(jobs) == 1
      assert jobs |> List.first() |> Map.get(:args) |> Map.get("parameters") == %{}
    end

    test "creates multiple jobs from template with codes", %{credential: credential} do
      # テスト用のジョブグループを作成
      {:ok, job_group} = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: credential.data_source_id,
        schedule: "0 * * * *",
        parameters_template: %{
          "codes" => ["7203", "9984"],
          "from" => "2024-01-01",
          "to" => "2024-01-31"
        },
        is_enabled: true
      } |> Repo.insert()

      assert {:ok, jobs} = JobGroupManager.create_jobs_for_group(job_group.id)
      assert length(jobs) == 2
      assert Enum.map(jobs, &(&1.args["parameters"]["code"])) |> Enum.sort() == ["7203", "9984"]
    end
  end

  describe "schedule management" do
    test "calculates next run time from cron expression" do
      # 現在時刻を固定
      now = ~N[2024-03-25 10:30:00]
      schedule = "0 * * * *"

      assert is_integer(JobGroupManager.calculate_next_run(schedule))
    end

    test "handles invalid cron expression" do
      assert JobGroupManager.calculate_next_run("invalid") == nil
    end

    test "schedules job group check" do
      # スケジュールチェックが設定されていることを確認
      assert Process.whereis(JobGroupManager)
      assert :sys.get_state(JobGroupManager) == %{}
    end
  end

  describe "error handling" do
    test "handles non-existent job group" do
      assert {:error, :not_found} = JobGroupManager.create_jobs_for_group(-1)
    end

    test "handles invalid schedule update", %{credential: credential} do
      # テスト用のジョブグループを作成
      {:ok, job_group} = %JobGroup{
        name: "Test Job Group",
        description: "Test Description",
        schema_module: "MoomooMarkets.Schemas.StockPrice",
        data_source_id: credential.data_source_id,
        schedule: "0 * * * *",
        parameters_template: %{
          "code" => "7203",
          "from" => "2024-01-01",
          "to" => "2024-01-31"
        },
        is_enabled: true
      } |> Repo.insert()

      assert {:error, _} = JobGroupManager.update_group_schedule(job_group.id, "invalid")
    end
  end
end
