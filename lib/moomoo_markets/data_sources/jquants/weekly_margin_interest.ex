defmodule MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest do
  @moduledoc """
  J-Quants APIから週間信用取引残高データを取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    code: String.t(),
    date: Date.t(),
    issue_type: String.t(),
    short_margin_trade_volume: float(),
    long_margin_trade_volume: float(),
    short_negotiable_margin_trade_volume: float(),
    long_negotiable_margin_trade_volume: float(),
    short_standardized_margin_trade_volume: float(),
    long_standardized_margin_trade_volume: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "weekly_margin_interests" do
    field :code, :string
    field :date, :date
    field :issue_type, :string
    field :short_margin_trade_volume, :float
    field :long_margin_trade_volume, :float
    field :short_negotiable_margin_trade_volume, :float
    field :long_negotiable_margin_trade_volume, :float
    field :short_standardized_margin_trade_volume, :float
    field :long_standardized_margin_trade_volume, :float

    timestamps()
  end

  @doc """
  指定された銘柄コードの週間信用取引残高データを取得します
  """
  @spec fetch_weekly_margin_interest(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_weekly_margin_interest(code, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_weekly_margin_interests(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  DataFetchWorkerから呼び出される関数。
  パラメータから銘柄コードと日付範囲を取得して週間信用取引残高データを取得します。

  ## パラメータ
    - params: %{
        "code" => "銘柄コード",
        "from_date" => "開始日 (YYYY-MM-DD)",
        "to_date" => "終了日 (YYYY-MM-DD)"
      }

  ## 戻り値
    - {:ok, [%__MODULE__{}]} - 成功時
    - {:error, %Error{}} - 失敗時
  """
  @spec fetch_data(map()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_data(%{"code" => code, "from_date" => from_date, "to_date" => to_date}) do
    with {:ok, from} <- Date.from_iso8601(from_date),
         {:ok, to} <- Date.from_iso8601(to_date),
         true <- is_binary(code),
         true <- String.length(code) > 0 do
      fetch_weekly_margin_interest(code, from, to)
    else
      false -> {:error, Error.error(:invalid_code, "Invalid code format")}
      {:error, _} -> {:error, Error.error(:invalid_date, "Invalid date format")}
    end
  end

  def fetch_data(_) do
    {:error, Error.error(:invalid_params, "Missing required parameters: code, from_date, to_date")}
  end

  @doc false
  def changeset(weekly_margin_interest, attrs) do
    weekly_margin_interest
    |> cast(attrs, [
      :code, :date, :issue_type,
      :short_margin_trade_volume, :long_margin_trade_volume,
      :short_negotiable_margin_trade_volume, :long_negotiable_margin_trade_volume,
      :short_standardized_margin_trade_volume, :long_standardized_margin_trade_volume
    ])
    |> validate_required([
      :code, :date, :issue_type,
      :short_margin_trade_volume, :long_margin_trade_volume,
      :short_negotiable_margin_trade_volume, :long_negotiable_margin_trade_volume,
      :short_standardized_margin_trade_volume, :long_standardized_margin_trade_volume
    ])
    |> unique_constraint([:code, :date, :issue_type])
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
    url = "#{base_url}/markets/weekly_margin_interest"
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

  defp parse_response(%{"weekly_margin_interest" => weekly_margin_interests}) do
    {:ok, Enum.map(weekly_margin_interests, &map_to_weekly_margin_interest/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_weekly_margin_interest(data) do
    %{
      code: data["Code"],
      date: Date.from_iso8601!(data["Date"]),
      issue_type: data["IssueType"],
      short_margin_trade_volume: data["ShortMarginTradeVolume"],
      long_margin_trade_volume: data["LongMarginTradeVolume"],
      short_negotiable_margin_trade_volume: data["ShortNegotiableMarginTradeVolume"],
      long_negotiable_margin_trade_volume: data["LongNegotiableMarginTradeVolume"],
      short_standardized_margin_trade_volume: data["ShortStandardizedMarginTradeVolume"],
      long_standardized_margin_trade_volume: data["LongStandardizedMarginTradeVolume"]
    }
  end

  defp save_weekly_margin_interests(weekly_margin_interests) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    weekly_margin_interests_with_timestamps = Enum.map(weekly_margin_interests, fn interest ->
      Map.merge(interest, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      weekly_margin_interests_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:code, :date, :issue_type]
    )
    {:ok, %{count: count}}
  end
end
