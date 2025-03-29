defmodule MoomooMarkets.Workers.DataFetchWorker do
  @moduledoc """
  Worker that fetches data based on the job group configuration.
  """

  use Oban.Worker
  require Logger
  alias MoomooMarkets.Jobs.JobGroup
  alias MoomooMarkets.DataSources.DataSource
  alias MoomooMarkets.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{id: job_id, args: %{
    "job_group_id" => job_group_id,
    "parameters" => parameters
  }}) do
    Logger.info("Starting data fetch job #{job_id} for group #{job_group_id}")
    with {:ok, job_group} <- get_job_group(job_group_id),
         {:ok, data_source} <- get_data_source(job_group.data_source_id),
         {:ok, schema_module} <- get_schema_module(job_group.schema_module),
         :ok <- validate_parameters(schema_module, parameters),
         {:ok, result} <- fetch_data(schema_module, data_source, parameters) do
      Logger.info("Successfully completed data fetch job #{job_id}")
      {:ok, result}
    else
      {:error, error} ->
        Logger.error("""
          Failed to fetch data for job #{job_id}:
          Group ID: #{job_group_id}
          Error: #{inspect(error)}
        """)
        {:error, error}
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(2)  # タイムアウトを2分に短縮

  @impl Oban.Worker
  def backoff(job) do
    case job.attempt do
      1 -> :timer.seconds(30)  # 30秒
      2 -> :timer.minutes(1)   # 1分
      3 -> :timer.minutes(2)   # 2分
      _ -> :timer.minutes(5)   # 5分
    end
  end

  # Private functions

  defp get_job_group(id) do
    case Repo.get(JobGroup, id) do
      nil -> {:error, %{type: :job_group_not_found, message: "Job group #{id} not found"}}
      job_group -> {:ok, job_group}
    end
  end

  defp get_data_source(id) do
    case Repo.get(DataSource, id) do
      nil -> {:error, %{type: :data_source_not_found, message: "Data source #{id} not found"}}
      data_source -> {:ok, data_source}
    end
  end

  defp get_schema_module(module_name) do
    case Code.ensure_loaded(Module.concat(Elixir, module_name)) do
      {:module, module} -> {:ok, module}
      {:error, reason} -> {:error, %{type: :module_not_found, message: "Module #{module_name} not found: #{inspect(reason)}"}}
    end
  end

  defp validate_parameters(schema_module, parameters) do
    case schema_module do
      MoomooMarkets.DataSources.JQuants.StockPrice ->
        validate_stock_price_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.Stock ->
        :ok  # パラメータ不要
      MoomooMarkets.DataSources.JQuants.TradingCalendar ->
        validate_date_range_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.Statement ->
        validate_statement_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest ->
        validate_date_range_parameters(parameters)
      _ ->
        {:error, %{type: :unsupported_schema_module, message: "Unsupported schema module: #{schema_module}"}}
    end
  end

  defp validate_stock_price_parameters(%{"code" => code, "from_date" => from_date, "to_date" => to_date}) do
    with {:ok, from} <- Date.from_iso8601(from_date),
         {:ok, to} <- Date.from_iso8601(to_date),
         true <- is_binary(code),
         true <- String.length(code) > 0,
         true <- Date.compare(from, to) in [:lt, :eq] do
      :ok
    else
      false -> {:error, %{type: :invalid_parameters, message: "Invalid date range or code format"}}
      {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
    end
  end

  defp validate_stock_price_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: code, from_date, to_date"}}

  defp validate_statement_parameters(%{"code" => code, "from_date" => from_date, "to_date" => to_date}) do
    with {:ok, from} <- Date.from_iso8601(from_date),
         {:ok, to} <- Date.from_iso8601(to_date),
         true <- is_binary(code),
         true <- String.length(code) > 0,
         true <- Date.compare(from, to) in [:lt, :eq] do
      :ok
    else
      false -> {:error, %{type: :invalid_parameters, message: "Invalid date range or code format"}}
      {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
    end
  end

  defp validate_statement_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: code, from_date, to_date"}}

  defp validate_date_range_parameters(%{"from_date" => from_date, "to_date" => to_date}) do
    with {:ok, from} <- Date.from_iso8601(from_date),
         {:ok, to} <- Date.from_iso8601(to_date),
         true <- Date.compare(from, to) in [:lt, :eq] do
      :ok
    else
      false -> {:error, %{type: :invalid_parameters, message: "Invalid date range"}}
      {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
    end
  end

  defp validate_date_range_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: from_date, to_date"}}

  defp fetch_data(schema_module, data_source, parameters) do
    case schema_module do
      MoomooMarkets.DataSources.JQuants.StockPrice ->
        case parameters do
          %{"code" => code, "from_date" => from_date, "to_date" => to_date} ->
            with {:ok, from} <- Date.from_iso8601(from_date),
                 {:ok, to} <- Date.from_iso8601(to_date) do
              schema_module.fetch_stock_prices(code, from, to)
            else
              {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
            end
          _ ->
            {:error, %{type: :invalid_parameters, message: "Missing required parameters"}}
        end
      MoomooMarkets.DataSources.JQuants.Stock ->
        schema_module.fetch_listed_info()
      MoomooMarkets.DataSources.JQuants.TradingCalendar ->
        case parameters do
          %{"from_date" => from_date, "to_date" => to_date} ->
            with {:ok, from} <- Date.from_iso8601(from_date),
                 {:ok, to} <- Date.from_iso8601(to_date) do
              schema_module.fetch_trading_calendar(from, to)
            else
              {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
            end
          _ ->
            {:error, %{type: :invalid_parameters, message: "Missing required parameters"}}
        end
      MoomooMarkets.DataSources.JQuants.Statement ->
        case parameters do
          %{"code" => code, "from_date" => from_date, "to_date" => to_date} ->
            with {:ok, from} <- Date.from_iso8601(from_date),
                 {:ok, to} <- Date.from_iso8601(to_date) do
              schema_module.fetch_statements(code, from, to)
            else
              {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
            end
          _ ->
            {:error, %{type: :invalid_parameters, message: "Missing required parameters"}}
        end
      MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest ->
        case parameters do
          %{"from_date" => from_date, "to_date" => to_date} ->
            with {:ok, from} <- Date.from_iso8601(from_date),
                 {:ok, to} <- Date.from_iso8601(to_date) do
              schema_module.fetch_weekly_margin_interests(from, to)
            else
              {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
            end
          _ ->
            {:error, %{type: :invalid_parameters, message: "Missing required parameters"}}
        end
      _ ->
        {:error, %{type: :unsupported_schema_module, message: "Unsupported schema module: #{schema_module}"}}
    end
  end
end
