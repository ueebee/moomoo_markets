defmodule MoomooMarkets.Jobs.JobGroupTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.Jobs.JobGroup
  alias MoomooMarkets.DataSources.DataSource

  describe "changeset/2" do
    setup do
      {:ok, data_source} = Repo.insert(%DataSource{
        name: "J-Quants",
        provider_type: "jquants",
        base_url: "http://localhost:4040"
      })

      %{data_source: data_source}
    end

    test "creates a valid changeset with required attributes", %{data_source: data_source} do
      attrs = %{
        name: "Stock Price Fetch",
        schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
        data_source_id: data_source.id,
        schedule: "0 0 * * *"
      }

      changeset = JobGroup.changeset(%JobGroup{}, attrs)
      assert changeset.valid?

      assert get_change(changeset, :name) == "Stock Price Fetch"
      assert get_change(changeset, :schema_module) == "MoomooMarkets.DataSources.JQuants.StockPrice"
      assert get_change(changeset, :data_source_id) == data_source.id
      assert get_change(changeset, :schedule) == "0 0 * * *"
      assert get_field(changeset, :is_enabled) == true
    end

    test "returns error changeset when required attributes are missing" do
      attrs = %{}

      changeset = JobGroup.changeset(%JobGroup{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
        name: ["can't be blank"],
        schema_module: ["can't be blank"],
        data_source_id: ["can't be blank"],
        schedule: ["can't be blank"]
      }
    end

    test "validates schedule format", %{data_source: data_source} do
      attrs = %{
        name: "Invalid Schedule",
        schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
        data_source_id: data_source.id,
        schedule: "invalid cron expression"
      }

      changeset = JobGroup.changeset(%JobGroup{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
        schedule: ["invalid cron expression"]
      }
    end
  end

  describe "ready_to_run?/1" do
    test "returns true when schedule is nil" do
      job_group = %JobGroup{schedule: nil}
      assert JobGroup.ready_to_run?(job_group)
    end

    test "returns true when schedule is valid" do
      job_group = %JobGroup{
        schedule: %{"type" => "cron", "expression" => "0 0 * * *"}
      }
      assert JobGroup.ready_to_run?(job_group)
    end
  end

  describe "calculate_next_run/1" do
    test "returns nil when schedule is nil" do
      job_group = %JobGroup{schedule: nil}
      assert JobGroup.calculate_next_run(job_group) == nil
    end

    test "returns next run time when schedule is present" do
      job_group = %JobGroup{schedule: "0 0 * * *"}
      next_run = JobGroup.calculate_next_run(job_group)
      assert DateTime.compare(next_run, DateTime.utc_now()) == :gt
    end
  end

  describe "update_schedule/2" do
    setup do
      {:ok, data_source} = Repo.insert(%DataSource{
        name: "J-Quants",
        provider_type: "jquants",
        base_url: "http://localhost:4040"
      })

      {:ok, job_group} = Repo.insert(%JobGroup{
        name: "Test Job",
        schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
        data_source_id: data_source.id,
        schedule: "0 0 * * *"
      })

      %{job_group: job_group}
    end

    test "updates schedule with valid cron expression", %{job_group: job_group} do
      new_schedule = "0 1 * * *"
      assert {:ok, updated_job_group} = JobGroup.update_schedule(job_group, new_schedule)
      assert updated_job_group.schedule == new_schedule
    end

    test "returns error with invalid cron expression", %{job_group: job_group} do
      new_schedule = "invalid cron"
      assert {:error, changeset} = JobGroup.update_schedule(job_group, new_schedule)
      assert errors_on(changeset) == %{schedule: ["invalid cron expression"]}
    end
  end

  describe "set_enabled/2" do
    setup do
      {:ok, data_source} = Repo.insert(%DataSource{
        name: "J-Quants",
        provider_type: "jquants",
        base_url: "http://localhost:4040"
      })

      {:ok, job_group} = Repo.insert(%JobGroup{
        name: "Test Job",
        schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
        data_source_id: data_source.id,
        schedule: "0 0 * * *"
      })

      %{job_group: job_group}
    end

    test "sets job group enabled status", %{job_group: job_group} do
      assert {:ok, updated_job_group} = JobGroup.set_enabled(job_group, false)
      assert updated_job_group.is_enabled == false

      assert {:ok, updated_job_group} = JobGroup.set_enabled(job_group, true)
      assert updated_job_group.is_enabled == true
    end
  end
end
