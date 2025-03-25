defmodule MoomooMarkets.DataSources.JQuants.StockPrice do
  @moduledoc """
  J-Quants APIから株価データを取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    code: String.t(),
    date: Date.t(),
    open: float(),
    high: float(),
    low: float(),
    close: float(),
    volume: float(),
    turnover_value: float(),
    adjustment_factor: float(),
    adjustment_open: float(),
    adjustment_high: float(),
    adjustment_low: float(),
    adjustment_close: float(),
    adjustment_volume: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "stock_prices" do
    field :code, :string
    field :date, :date
    field :open, :float
    field :high, :float
    field :low, :float
    field :close, :float
    field :volume, :float
    field :turnover_value, :float
    field :adjustment_factor, :float
    field :adjustment_open, :float
    field :adjustment_high, :float
    field :adjustment_low, :float
    field :adjustment_close, :float
    field :adjustment_volume, :float

    timestamps()
  end

  @doc """
  指定された銘柄コードの株価四本値データを取得します
  """
  @spec fetch_stock_prices(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_stock_prices(code, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_stock_prices(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  全銘柄の株価四本値データを取得します
  """
  @spec fetch_all_stock_prices(Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_all_stock_prices(date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, date),
         {:ok, data} <- parse_response(response) do
      save_stock_prices(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(stock_price, attrs) do
    stock_price
    |> cast(attrs, [:code, :date, :open, :high, :low, :close, :volume, :turnover_value,
                    :adjustment_factor, :adjustment_open, :adjustment_high, :adjustment_low,
                    :adjustment_close, :adjustment_volume])
    |> validate_required([:code, :date, :open, :high, :low, :close, :volume, :turnover_value,
                         :adjustment_factor, :adjustment_open, :adjustment_high, :adjustment_low,
                         :adjustment_close, :adjustment_volume])
    |> unique_constraint([:code, :date])
  end

  # Private functions

  defp get_credential do
    query =
      from c in MoomooMarkets.DataSources.DataSourceCredential,
        join: d in MoomooMarkets.DataSources.DataSource,
        on: c.data_source_id == d.id,
        where: d.provider_type == "jquants",
        select: {c, d.base_url}

    case Repo.one(query) do
      nil -> {:error, Error.error(:credential_not_found, "J-Quants credential not found")}
      {credential, base_url} -> {:ok, %{credential: credential, base_url: base_url}}
    end
  end

  defp make_request(%{credential: _credential, base_url: base_url}, id_token, code, from_date, to_date) do
    url = "#{base_url}/prices/daily_quotes"
    params = %{
      code: code,
      from: Date.to_iso8601(from_date),
      to: Date.to_iso8601(to_date)
    }
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %{status: status, body: %{"message" => message}}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status, message: message})}
      {:ok, %{status: status}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status})}
      {:error, %{reason: reason}} ->
        {:error, Error.error(:http_error, "HTTP request failed", %{reason: reason})}
    end
  end

  defp make_request(%{credential: _credential, base_url: base_url}, id_token, date) do
    url = "#{base_url}/prices/daily_quotes"
    params = %{date: Date.to_iso8601(date)}
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %{status: status, body: %{"message" => message}}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status, message: message})}
      {:ok, %{status: status}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status})}
      {:error, %{reason: reason}} ->
        {:error, Error.error(:http_error, "HTTP request failed", %{reason: reason})}
    end
  end

  defp parse_response(%{"daily_quotes" => daily_quotes}) do
    {:ok, Enum.map(daily_quotes, &map_to_stock_price/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_stock_price(data) do
    %{
      code: data["Code"],
      date: Date.from_iso8601!(data["Date"]),
      open: data["Open"],
      high: data["High"],
      low: data["Low"],
      close: data["Close"],
      volume: data["Volume"],
      turnover_value: data["TurnoverValue"],
      adjustment_factor: data["AdjustmentFactor"],
      adjustment_open: data["AdjustmentOpen"],
      adjustment_high: data["AdjustmentHigh"],
      adjustment_low: data["AdjustmentLow"],
      adjustment_close: data["AdjustmentClose"],
      adjustment_volume: data["AdjustmentVolume"]
    }
  end

  defp save_stock_prices(stock_prices) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    stock_prices_with_timestamps = Enum.map(stock_prices, fn price ->
      Map.merge(price, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      stock_prices_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:code, :date]
    )
    {:ok, %{count: count}}
  end
end
