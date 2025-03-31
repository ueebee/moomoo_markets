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
  def perform(%Oban.Job{id: job_id, args: %{"job_group_id" => job_group_id, "parameters" => parameters}}) do
    Logger.info("Starting data fetch job #{job_id} for group #{job_group_id}")
    with {:ok, job_group} <- get_job_group(job_group_id),
         {:ok, data_source} <- get_data_source(job_group.data_source_id),
         {:ok, schema_module} <- get_schema_module(job_group),
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

  defp get_job_group(job_group_id) do
    case Repo.get(JobGroup, job_group_id) do
      nil -> {:error, :job_group_not_found}
      job_group -> {:ok, job_group}
    end
  end

  defp get_data_source(id) do
    case Repo.get(DataSource, id) do
      nil -> {:error, %{type: :data_source_not_found, message: "Data source #{id} not found"}}
      data_source -> {:ok, data_source}
    end
  end

  defp get_schema_module(job_group) do
    case Code.ensure_loaded(Module.concat(Elixir, job_group.schema_module)) do
      {:module, module} -> {:ok, module}
      {:error, _} -> {:error, :invalid_schema_module}
    end
  end

  defp validate_parameters(schema_module, parameters) do
    case schema_module do
      MoomooMarkets.DataSources.JQuants.Stock ->
        :ok
      MoomooMarkets.DataSources.JQuants.Statement ->
        validate_statement_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest ->
        validate_date_range_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.Breakdown ->
        validate_breakdown_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.Index ->
        validate_index_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.ShortSelling ->
        validate_short_selling_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.TradesSpec ->
        validate_trades_spec_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.TradingCalendar ->
        validate_date_range_parameters(parameters)
      MoomooMarkets.DataSources.JQuants.StockPrice ->
        validate_stock_price_parameters(parameters)
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

  defp validate_breakdown_parameters(%{"code" => code, "from_date" => from_date, "to_date" => to_date}) do
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

  defp validate_breakdown_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: code, from_date, to_date"}}

  defp validate_index_parameters(%{"code" => code, "from_date" => from_date, "to_date" => to_date}) do
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

  defp validate_index_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: code, from_date, to_date"}}

  defp validate_short_selling_parameters(%{"sector33_code" => code, "from_date" => from_date, "to_date" => to_date}) do
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

  defp validate_short_selling_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: sector33_code, from_date, to_date"}}

  defp validate_trades_spec_parameters(%{"section" => section, "from_date" => from_date, "to_date" => to_date}) do
    with {:ok, from} <- Date.from_iso8601(from_date),
         {:ok, to} <- Date.from_iso8601(to_date),
         true <- is_binary(section),
         true <- String.length(section) > 0,
         true <- Date.compare(from, to) in [:lt, :eq] do
      :ok
    else
      false -> {:error, %{type: :invalid_parameters, message: "Invalid date range or section format"}}
      {:error, _} -> {:error, %{type: :invalid_date_format, message: "Invalid date format"}}
    end
  end

  defp validate_trades_spec_parameters(_), do:
    {:error, %{type: :invalid_parameters, message: "Missing required parameters: section, from_date, to_date"}}

  defp fetch_data(schema_module, _data_source, parameters) do
    try do
      schema_module.fetch_data(parameters)
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end
