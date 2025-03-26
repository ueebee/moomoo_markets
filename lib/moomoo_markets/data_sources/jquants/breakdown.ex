defmodule MoomooMarkets.DataSources.JQuants.Breakdown do
  @moduledoc """
  J-Quants APIから売買内訳データを取得し、データベースに保存します。
  東証上場銘柄の東証市場における銘柄別の日次売買代金・売買高（立会内取引に限る）について、
  信用取引や空売りの利用に関する発注時のフラグ情報を用いて細分化したデータを記録します。
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias MoomooMarkets.DataSources.JQuants.{Auth, Error}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    date: Date.t(),
    code: String.t(),
    long_sell_value: float(),
    short_sell_without_margin_value: float(),
    margin_sell_new_value: float(),
    margin_sell_close_value: float(),
    long_buy_value: float(),
    margin_buy_new_value: float(),
    margin_buy_close_value: float(),
    long_sell_volume: float(),
    short_sell_without_margin_volume: float(),
    margin_sell_new_volume: float(),
    margin_sell_close_volume: float(),
    long_buy_volume: float(),
    margin_buy_new_volume: float(),
    margin_buy_close_volume: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "breakdowns" do
    field :date, :date
    field :code, :string
    field :long_sell_value, :float
    field :short_sell_without_margin_value, :float
    field :margin_sell_new_value, :float
    field :margin_sell_close_value, :float
    field :long_buy_value, :float
    field :margin_buy_new_value, :float
    field :margin_buy_close_value, :float
    field :long_sell_volume, :float
    field :short_sell_without_margin_volume, :float
    field :margin_sell_new_volume, :float
    field :margin_sell_close_volume, :float
    field :long_buy_volume, :float
    field :margin_buy_new_volume, :float
    field :margin_buy_close_volume, :float

    timestamps()
  end

  @doc """
  指定された銘柄コードと日付範囲で売買内訳データを取得します。

  ## パラメータ
    - code: 銘柄コード（例: "13010"）
    - from_date: 開始日
    - to_date: 終了日

  ## 戻り値
    - {:ok, [%__MODULE__{}]} - 成功時
    - {:error, %Error{}} - 失敗時

  ## 例
      iex> fetch_breakdown("13010", ~D[2024-03-20], ~D[2024-03-25])
      {:ok, [%__MODULE__{...}]}
  """
  @spec fetch_breakdown(String.t(), Date.t(), Date.t()) ::
          {:ok, [t()]} | {:error, Error.t()}
  def fetch_breakdown(code, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_breakdowns(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(breakdown, attrs) do
    breakdown
    |> cast(attrs, [
      :date, :code,
      :long_sell_value, :short_sell_without_margin_value,
      :margin_sell_new_value, :margin_sell_close_value,
      :long_buy_value, :margin_buy_new_value, :margin_buy_close_value,
      :long_sell_volume, :short_sell_without_margin_volume,
      :margin_sell_new_volume, :margin_sell_close_volume,
      :long_buy_volume, :margin_buy_new_volume, :margin_buy_close_volume
    ])
    |> validate_required([
      :date, :code,
      :long_sell_value, :short_sell_without_margin_value,
      :margin_sell_new_value, :margin_sell_close_value,
      :long_buy_value, :margin_buy_new_value, :margin_buy_close_value,
      :long_sell_volume, :short_sell_without_margin_volume,
      :margin_sell_new_volume, :margin_sell_close_volume,
      :long_buy_volume, :margin_buy_new_volume, :margin_buy_close_volume
    ])
    |> unique_constraint([:date, :code])
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
    url = "#{base_url}/markets/breakdown"
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

  defp parse_response(%{"breakdown" => breakdowns}) do
    {:ok, Enum.map(breakdowns, &map_to_breakdown/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_breakdown(data) do
    %{
      date: Date.from_iso8601!(data["Date"]),
      code: data["Code"],
      long_sell_value: data["LongSellValue"],
      short_sell_without_margin_value: data["ShortSellWithoutMarginValue"],
      margin_sell_new_value: data["MarginSellNewValue"],
      margin_sell_close_value: data["MarginSellCloseValue"],
      long_buy_value: data["LongBuyValue"],
      margin_buy_new_value: data["MarginBuyNewValue"],
      margin_buy_close_value: data["MarginBuyCloseValue"],
      long_sell_volume: data["LongSellVolume"],
      short_sell_without_margin_volume: data["ShortSellWithoutMarginVolume"],
      margin_sell_new_volume: data["MarginSellNewVolume"],
      margin_sell_close_volume: data["MarginSellCloseVolume"],
      long_buy_volume: data["LongBuyVolume"],
      margin_buy_new_volume: data["MarginBuyNewVolume"],
      margin_buy_close_volume: data["MarginBuyCloseVolume"]
    }
  end

  defp save_breakdowns(breakdowns) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    breakdowns_with_timestamps = Enum.map(breakdowns, fn breakdown ->
      Map.merge(breakdown, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      breakdowns_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:date, :code]
    )
    {:ok, %{count: count}}
  end
end
