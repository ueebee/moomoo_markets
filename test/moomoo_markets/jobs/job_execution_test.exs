defmodule MoomooMarkets.Jobs.JobExecutionTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.Jobs.{JobExecution, Job, JobGroup}

  describe "changeset/2" do
    test "creates a valid changeset with required attributes" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      valid_attrs = %{
        job_id: job.id,
        started_at: DateTime.utc_now() |> DateTime.truncate(:second),
        status: :running
      }

      changeset = JobExecution.changeset(%JobExecution{}, valid_attrs)
      assert changeset.valid?

      job_execution = changeset |> Repo.insert!()
      assert job_execution.job_id == job.id
      assert job_execution.started_at != nil
      assert job_execution.status == :running
    end

    test "returns error changeset when required attributes are missing" do
      changeset = JobExecution.changeset(%JobExecution{}, %{})
      refute changeset.valid?

      assert errors_on(changeset) == %{
        job_id: ["can't be blank"],
        started_at: ["can't be blank"],
        status: ["can't be blank"]
      }
    end

    test "returns error changeset when status is invalid" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      invalid_attrs = %{
        job_id: job.id,
        started_at: DateTime.utc_now() |> DateTime.truncate(:second),
        status: :invalid_status
      }

      changeset = JobExecution.changeset(%JobExecution{}, invalid_attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
        status: ["is invalid"]
      }
    end

    test "returns error changeset when completed_at is before started_at" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      started_at = DateTime.utc_now() |> DateTime.truncate(:second)
      completed_at = DateTime.add(started_at, -3600)

      invalid_attrs = %{
        job_id: job.id,
        started_at: started_at,
        completed_at: completed_at,
        status: :completed
      }

      changeset = JobExecution.changeset(%JobExecution{}, invalid_attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
        completed_at: ["must be after started_at"]
      }
    end
  end

  describe "start/1" do
    test "creates a new job execution with running status" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      job_execution = JobExecution.start(job.id) |> Repo.insert!()

      assert job_execution.job_id == job.id
      assert job_execution.started_at != nil
      assert job_execution.status == :running
      assert job_execution.completed_at == nil
      assert job_execution.result == nil
      assert job_execution.error == nil
      assert job_execution.execution_time == nil
      assert job_execution.memory_usage == nil
      assert job_execution.retry_count == 0
    end
  end

  describe "complete/2" do
    test "updates job execution with completion details" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      job_execution = JobExecution.start(job.id) |> Repo.insert!()
      completed_execution = JobExecution.complete(job_execution, %{result: "success"}) |> Repo.update!()

      assert completed_execution.status == :completed
      assert completed_execution.completed_at != nil
      assert completed_execution.result == %{result: "success"}
      assert completed_execution.execution_time != nil
    end
  end

  describe "fail/2" do
    test "updates job execution with error details" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      job_execution = JobExecution.start(job.id) |> Repo.insert!()
      failed_execution = JobExecution.fail(job_execution, "Test error") |> Repo.update!()

      assert failed_execution.status == :failed
      assert failed_execution.completed_at != nil
      assert failed_execution.error == "Test error"
      assert failed_execution.execution_time != nil
    end
  end

  describe "retry/1" do
    test "updates job execution for retry" do
      job_group = %JobGroup{
        name: "Test Group",
        description: "Test Description",
        data_source: "test_source",
        schedule: %{
          "type" => "cron",
          "expression" => "0 * * * *",
          "timezone" => "Asia/Tokyo"
        }
      } |> Repo.insert!()

      job = %Job{
        name: "Test Job",
        description: "Test Description",
        job_group_id: job_group.id,
        parameters: %{
          "module" => "TestModule",
          "function" => "test_function",
          "args" => []
        }
      } |> Repo.insert!()

      job_execution = JobExecution.start(job.id) |> Repo.insert!()
      failed_execution = JobExecution.fail(job_execution, "Test error") |> Repo.update!()
      retried_execution = JobExecution.retry(failed_execution) |> Repo.update!()

      assert retried_execution.status == :running
      assert retried_execution.completed_at == nil
      assert retried_execution.error == nil
      assert retried_execution.execution_time == nil
      assert retried_execution.retry_count == 1
    end
  end
end
