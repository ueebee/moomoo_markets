defmodule MoomooMarkets.DataSources.JQuants.Index do
  @moduledoc """
  J-Quants APIから指数四本値データを取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types, IndexCodes}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    date: Date.t(),
    code: String.t(),
    open: float(),
    high: float(),
    low: float(),
    close: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "indices" do
    field :date, :date
    field :code, :string
    field :open, :float
    field :high, :float
    field :low, :float
    field :close, :float

    timestamps()
  end

  @doc """
  指定された指数コードの四本値データを取得します。
  """
  @spec fetch_indices(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_indices(code, from_date, to_date) do
    with true <- IndexCodes.valid_code?(code),
         {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_indices(data)
    else
      false -> {:error, Error.error(:invalid_code, "Invalid index code: #{code}")}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(index, attrs) do
    index
    |> cast(attrs, [:date, :code, :open, :high, :low, :close])
    |> validate_required([:date, :code, :open, :high, :low, :close])
    |> validate_number(:high, greater_than_or_equal_to: :open, message: "高値は始値以上である必要があります")
    |> validate_number(:low, less_than_or_equal_to: :high, message: "安値は高値以下である必要があります")
    |> validate_number(:close, greater_than_or_equal_to: :low, message: "終値は安値以上である必要があります")
    |> validate_number(:close, less_than_or_equal_to: :high, message: "終値は高値以下である必要があります")
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
    url = "#{base_url}/indices"
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

  defp parse_response(%{"indices" => indices}) do
    {:ok, Enum.map(indices, &map_to_index/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_index(data) do
    %{
      date: Date.from_iso8601!(data["Date"]),
      code: data["Code"],
      open: data["Open"],
      high: data["High"],
      low: data["Low"],
      close: data["Close"]
    }
  end

  defp save_indices(indices) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    indices_with_timestamps = Enum.map(indices, fn index ->
      Map.merge(index, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      indices_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:date, :code]
    )
    {:ok, %{count: count}}
  end
end
