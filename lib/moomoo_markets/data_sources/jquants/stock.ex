defmodule MoomooMarkets.DataSources.JQuants.Stock do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    code: String.t(),
    name: String.t(),
    name_en: String.t() | nil,
    sector_code: String.t() | nil,
    sector_name: String.t() | nil,
    sub_sector_code: String.t() | nil,
    sub_sector_name: String.t() | nil,
    scale_category: String.t() | nil,
    market_code: String.t() | nil,
    market_name: String.t() | nil,
    margin_code: String.t() | nil,
    margin_name: String.t() | nil,
    effective_date: Date.t(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "stocks" do
    field :code, :string
    field :name, :string
    field :name_en, :string
    field :sector_code, :string
    field :sector_name, :string
    field :sub_sector_code, :string
    field :sub_sector_name, :string
    field :scale_category, :string
    field :market_code, :string
    field :market_name, :string
    field :margin_code, :string
    field :margin_name, :string
    field :effective_date, :date

    timestamps()
  end

  @doc false
  def changeset(stock, attrs) do
    stock
    |> cast(attrs, [:code, :name, :name_en, :sector_code, :sector_name, :sub_sector_code, :sub_sector_name, :scale_category, :market_code, :market_name, :margin_code, :margin_name, :effective_date])
    |> validate_required([:code, :name, :effective_date])
    |> unique_constraint([:code, :effective_date])
  end

  @doc """
  J-Quants APIから上場情報を取得し、データベースに保存します
  """
  @spec fetch_listed_info() :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_listed_info do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token),
         {:ok, data} <- parse_response(response) do
      save_listed_info(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec save_listed_info([Types.listed_info()]) :: {:ok, [t()]} | {:error, Error.t()}
  defp save_listed_info(listed_info) do
    today = Date.utc_today()
    now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    listed_info
    |> Enum.map(&map_to_stock(&1, today, now))
    |> Enum.chunk_every(100)
    |> Enum.reduce_while({:ok, []}, &save_chunk/2)
  end

  @spec map_to_stock(Types.listed_info(), Date.t(), NaiveDateTime.t()) :: map()
  defp map_to_stock(info, today, now) do
    %{
      code: info["Code"],
      name: info["CompanyName"],
      name_en: info["CompanyNameEnglish"],
      sector_code: info["Sector17Code"],
      sector_name: info["Sector17CodeName"],
      sub_sector_code: info["Sector33Code"],
      sub_sector_name: info["Sector33CodeName"],
      scale_category: info["ScaleCategory"],
      market_code: info["MarketCode"],
      market_name: info["MarketCodeName"],
      margin_code: info["MarginCode"],
      margin_name: info["MarginCodeName"],
      effective_date: today,
      inserted_at: now,
      updated_at: now
    }
  end

  @spec save_chunk([map()], {:ok, [t()]}) :: {:cont, {:ok, [t()]}} | {:halt, {:error, Error.t()}}
  defp save_chunk(chunk, {:ok, acc}) do
    case Repo.insert_all(__MODULE__, chunk, on_conflict: :replace_all, conflict_target: [:code, :effective_date]) do
      {n, _} when is_integer(n) -> {:cont, {:ok, [n | acc]}}
      {:error, reason} -> {:halt, {:error, Error.error(:database_error, "Failed to save stocks", %{reason: reason})}}
    end
  end

  @spec get_credential() :: {:ok, %{credential: map(), base_url: String.t()}} | {:error, Error.t()}
  defp get_credential do
    query =
      from c in MoomooMarkets.DataSources.DataSourceCredential,
        join: d in MoomooMarkets.DataSources.DataSource,
        on: c.data_source_id == d.id,
        where: d.provider_type == "jquants",
        select: {c, d.base_url}

    case MoomooMarkets.Repo.one(query) do
      nil -> {:error, Error.error(:credential_not_found, "J-Quants credential not found")}
      {credential, base_url} -> {:ok, %{credential: credential, base_url: base_url}}
    end
  end

  @spec make_request(%{credential: map(), base_url: String.t()}, String.t()) :: {:ok, map()} | {:error, Error.t()}
  defp make_request(%{credential: _credential, base_url: base_url}, id_token) do
    url = "#{base_url}/listed/info"
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %{status: status, body: body}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status, body: body})}
      {:error, %{reason: reason}} ->
        {:error, Error.error(:http_error, "HTTP request failed", %{reason: reason})}
    end
  end

  @spec parse_response(map() | String.t()) :: {:ok, [Types.listed_info()]} | {:error, Error.t()}
  defp parse_response(%{"info" => listed_info}) when is_list(listed_info) do
    {:ok, listed_info}
  end

  defp parse_response(response) when is_binary(response) do
    case Jason.decode(response) do
      {:ok, %{"info" => listed_info}} when is_list(listed_info) ->
        {:ok, listed_info}
      {:ok, _} ->
        {:error, Error.error(:invalid_response, "Invalid response format")}
      {:error, reason} ->
        {:error, Error.error(:json_error, "Failed to parse JSON", %{reason: reason})}
    end
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end
end
