defmodule MoomooMarkets.DataSources.JQuants.Stock do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias MoomooMarkets.DataSources.JQuants.Auth
  alias MoomooMarkets.Repo

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

  defp save_listed_info(listed_info) do
    today = Date.utc_today()
    now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    listed_info
    |> Enum.map(fn info ->
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
    end)
    |> Enum.chunk_every(100)
    |> Enum.reduce_while({:ok, []}, fn chunk, {:ok, acc} ->
      case Repo.insert_all(__MODULE__, chunk, on_conflict: :replace_all, conflict_target: [:code, :effective_date]) do
        {n, _} when is_integer(n) -> {:cont, {:ok, [n | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp get_credential do
    query =
      from c in MoomooMarkets.DataSources.DataSourceCredential,
        join: d in MoomooMarkets.DataSources.DataSource,
        on: c.data_source_id == d.id,
        where: d.provider_type == "jquants",
        select: {c, d.base_url}

    case MoomooMarkets.Repo.one(query) do
      nil -> {:error, "J-Quants credential not found"}
      {credential, base_url} -> {:ok, %{credential: credential, base_url: base_url}}
    end
  end

  defp make_request(%{credential: _credential, base_url: base_url}, id_token) do
    url = "#{base_url}/listed/info"
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %{status: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{inspect(body)}"}
      {:error, %{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp parse_response(%{"info" => listed_info}) when is_list(listed_info) do
    {:ok, listed_info}
  end

  defp parse_response(response) when is_binary(response) do
    case Jason.decode(response) do
      {:ok, %{"info" => listed_info}} when is_list(listed_info) ->
        {:ok, listed_info}
      {:ok, _} ->
        {:error, "Invalid response format"}
      {:error, reason} ->
        {:error, "Failed to parse JSON: #{inspect(reason)}"}
    end
  end

  defp parse_response(_) do
    {:error, "Invalid response format"}
  end
end
