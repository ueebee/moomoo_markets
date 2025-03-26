defmodule MoomooMarkets.DataSources.JQuants.ShortSelling do
  @moduledoc """
  J-Quants APIから業種別空売り比率データを取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types, Sector33Codes}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    date: Date.t(),
    sector33_code: String.t(),
    selling_excluding_short_selling_turnover_value: float(),
    short_selling_with_restrictions_turnover_value: float(),
    short_selling_without_restrictions_turnover_value: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "short_sellings" do
    field :date, :date
    field :sector33_code, :string
    field :selling_excluding_short_selling_turnover_value, :float
    field :short_selling_with_restrictions_turnover_value, :float
    field :short_selling_without_restrictions_turnover_value, :float

    timestamps()
  end

  @doc """
  指定された業種コードの空売り比率データを取得します
  """
  @spec fetch_short_selling(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_short_selling(sector33_code, from_date, to_date) do
    with :ok <- validate_sector33_code(sector33_code),
         {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, sector33_code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_short_sellings(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(short_selling, attrs) do
    short_selling
    |> cast(attrs, [
      :date, :sector33_code,
      :selling_excluding_short_selling_turnover_value,
      :short_selling_with_restrictions_turnover_value,
      :short_selling_without_restrictions_turnover_value
    ])
    |> validate_required([
      :date, :sector33_code,
      :selling_excluding_short_selling_turnover_value,
      :short_selling_with_restrictions_turnover_value,
      :short_selling_without_restrictions_turnover_value
    ])
    |> unique_constraint([:date, :sector33_code])
  end

  # Private functions

  defp validate_sector33_code(code) do
    if Sector33Codes.valid_code?(code) do
      :ok
    else
      {:error, Error.error(:invalid_sector33_code, "Invalid sector33 code: #{code}")}
    end
  end

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

  defp make_request(%{credential: _credential, base_url: base_url}, id_token, sector33_code, from_date, to_date) do
    url = "#{base_url}/markets/short_selling"
    params = %{
      sector33code: sector33_code,
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

  defp parse_response(%{"short_selling" => short_sellings}) do
    {:ok, Enum.map(short_sellings, &map_to_short_selling/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_short_selling(data) do
    %{
      date: Date.from_iso8601!(data["Date"]),
      sector33_code: data["Sector33Code"],
      selling_excluding_short_selling_turnover_value: data["SellingExcludingShortSellingTurnoverValue"],
      short_selling_with_restrictions_turnover_value: data["ShortSellingWithRestrictionsTurnoverValue"],
      short_selling_without_restrictions_turnover_value: data["ShortSellingWithoutRestrictionsTurnoverValue"]
    }
  end

  defp save_short_sellings(short_sellings) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    short_sellings_with_timestamps = Enum.map(short_sellings, fn selling ->
      Map.merge(selling, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      short_sellings_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:date, :sector33_code]
    )
    {:ok, %{count: count}}
  end
end
