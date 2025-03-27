defmodule MoomooMarkets.DataSources.JQuants.TradingCalendar do
  @moduledoc """
  J-Quants APIから取引カレンダー情報を取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error}
  alias MoomooMarkets.Repo

  @holiday_divisions ["1", "2", "3"]

  @type holiday_division :: String.t()

  @type t :: %__MODULE__{
    date: Date.t(),
    holiday_division: holiday_division(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "trading_calendars" do
    field :date, :date
    field :holiday_division, :string

    timestamps()
  end

  @doc """
  利用可能な休日区分の一覧を取得します。
  """
  @spec available_holiday_divisions() :: [holiday_division()]
  def available_holiday_divisions, do: @holiday_divisions

  @doc """
  指定された休日区分が有効かどうかを確認します。
  """
  @spec valid_holiday_division?(String.t()) :: boolean()
  def valid_holiday_division?(division), do: division in @holiday_divisions

  @doc """
  指定された期間の取引カレンダー情報を取得します。

  ## パラメータ
    - from_date: 開始日
    - to_date: 終了日

  ## 戻り値
    - {:ok, [%__MODULE__{}]} - 成功時
    - {:error, %Error{}} - 失敗時

  ## 例
      iex> fetch_trading_calendar(~D[2024-01-01], ~D[2024-12-31])
      {:ok, [%__MODULE__{...}]}
  """
  @spec fetch_trading_calendar(Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_trading_calendar(from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_trading_calendars(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(trading_calendar, attrs) do
    trading_calendar
    |> cast(attrs, [:date, :holiday_division])
    |> validate_required([:date, :holiday_division])
    |> validate_inclusion(:holiday_division, @holiday_divisions)
    |> unique_constraint([:date])
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

  defp make_request(%{credential: _credential, base_url: base_url}, id_token, from_date, to_date) do
    url = "#{base_url}/markets/trading_calendar"
    params = %{
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

  defp parse_response(%{"trading_calendar" => trading_calendars}) do
    {:ok, Enum.map(trading_calendars, &map_to_trading_calendar/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_trading_calendar(data) do
    %{
      date: Date.from_iso8601!(data["Date"]),
      holiday_division: data["HolidayDivision"]
    }
  end

  defp save_trading_calendars(trading_calendars) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    trading_calendars_with_timestamps = Enum.map(trading_calendars, fn calendar ->
      Map.merge(calendar, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      trading_calendars_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:date]
    )
    {:ok, %{count: count}}
  end
end
