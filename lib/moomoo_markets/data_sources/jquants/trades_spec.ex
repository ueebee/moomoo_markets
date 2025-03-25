defmodule MoomooMarkets.DataSources.JQuants.TradesSpec do
  @moduledoc """
  J-Quants APIから投資部門別売買状況を取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types}
  alias MoomooMarkets.Repo

  @market_sections [
    "TSEPrime",
    "TSEStandard",
    "TSEContinuous",
    "TSE1st",
    "TSE2nd",
    "TSEJASDAQ",
    "TSEJASDAQStandard",
    "TSEJASDAQGrowth"
  ]

  @type market_section :: String.t()

  @type t :: %__MODULE__{
    published_date: Date.t(),
    start_date: Date.t(),
    end_date: Date.t(),
    section: market_section(),
    # 自己計
    proprietary_sales: float(),
    proprietary_purchases: float(),
    proprietary_total: float(),
    proprietary_balance: float(),
    # 委託計
    brokerage_sales: float(),
    brokerage_purchases: float(),
    brokerage_total: float(),
    brokerage_balance: float(),
    # 総計
    total_sales: float(),
    total_purchases: float(),
    total_total: float(),
    total_balance: float(),
    # 個人
    individuals_sales: float(),
    individuals_purchases: float(),
    individuals_total: float(),
    individuals_balance: float(),
    # 外国人
    foreigners_sales: float(),
    foreigners_purchases: float(),
    foreigners_total: float(),
    foreigners_balance: float(),
    # 証券会社
    securities_cos_sales: float(),
    securities_cos_purchases: float(),
    securities_cos_total: float(),
    securities_cos_balance: float(),
    # 投資信託
    investment_trusts_sales: float(),
    investment_trusts_purchases: float(),
    investment_trusts_total: float(),
    investment_trusts_balance: float(),
    # 事業法人
    business_cos_sales: float(),
    business_cos_purchases: float(),
    business_cos_total: float(),
    business_cos_balance: float(),
    # その他法人
    other_cos_sales: float(),
    other_cos_purchases: float(),
    other_cos_total: float(),
    other_cos_balance: float(),
    # 生保・損保
    insurance_cos_sales: float(),
    insurance_cos_purchases: float(),
    insurance_cos_total: float(),
    insurance_cos_balance: float(),
    # 都銀・地銀等
    city_bks_regional_bks_etc_sales: float(),
    city_bks_regional_bks_etc_purchases: float(),
    city_bks_regional_bks_etc_total: float(),
    city_bks_regional_bks_etc_balance: float(),
    # 信託銀行
    trust_banks_sales: float(),
    trust_banks_purchases: float(),
    trust_banks_total: float(),
    trust_banks_balance: float(),
    # その他金融機関
    other_financial_institutions_sales: float(),
    other_financial_institutions_purchases: float(),
    other_financial_institutions_total: float(),
    other_financial_institutions_balance: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "trades_specs" do
    field :published_date, :date
    field :start_date, :date
    field :end_date, :date
    field :section, :string
    # 自己計
    field :proprietary_sales, :float
    field :proprietary_purchases, :float
    field :proprietary_total, :float
    field :proprietary_balance, :float
    # 委託計
    field :brokerage_sales, :float
    field :brokerage_purchases, :float
    field :brokerage_total, :float
    field :brokerage_balance, :float
    # 総計
    field :total_sales, :float
    field :total_purchases, :float
    field :total_total, :float
    field :total_balance, :float
    # 個人
    field :individuals_sales, :float
    field :individuals_purchases, :float
    field :individuals_total, :float
    field :individuals_balance, :float
    # 外国人
    field :foreigners_sales, :float
    field :foreigners_purchases, :float
    field :foreigners_total, :float
    field :foreigners_balance, :float
    # 証券会社
    field :securities_cos_sales, :float
    field :securities_cos_purchases, :float
    field :securities_cos_total, :float
    field :securities_cos_balance, :float
    # 投資信託
    field :investment_trusts_sales, :float
    field :investment_trusts_purchases, :float
    field :investment_trusts_total, :float
    field :investment_trusts_balance, :float
    # 事業法人
    field :business_cos_sales, :float
    field :business_cos_purchases, :float
    field :business_cos_total, :float
    field :business_cos_balance, :float
    # その他法人
    field :other_cos_sales, :float
    field :other_cos_purchases, :float
    field :other_cos_total, :float
    field :other_cos_balance, :float
    # 生保・損保
    field :insurance_cos_sales, :float
    field :insurance_cos_purchases, :float
    field :insurance_cos_total, :float
    field :insurance_cos_balance, :float
    # 都銀・地銀等
    field :city_bks_regional_bks_etc_sales, :float
    field :city_bks_regional_bks_etc_purchases, :float
    field :city_bks_regional_bks_etc_total, :float
    field :city_bks_regional_bks_etc_balance, :float
    # 信託銀行
    field :trust_banks_sales, :float
    field :trust_banks_purchases, :float
    field :trust_banks_total, :float
    field :trust_banks_balance, :float
    # その他金融機関
    field :other_financial_institutions_sales, :float
    field :other_financial_institutions_purchases, :float
    field :other_financial_institutions_total, :float
    field :other_financial_institutions_balance, :float

    timestamps()
  end

  @doc """
  利用可能な市場区分の一覧を取得します。
  """
  @spec available_sections() :: [market_section()]
  def available_sections, do: @market_sections

  @doc """
  指定された市場区分が有効かどうかを確認します。
  """
  @spec valid_section?(String.t()) :: boolean()
  def valid_section?(section), do: section in @market_sections

  @doc """
  指定された市場区分の投資部門別売買状況を取得します。
  """
  @spec fetch_trades_spec(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_trades_spec(section, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, section, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_trades_specs(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(trades_spec, attrs) do
    trades_spec
    |> cast(attrs, [
      :published_date, :start_date, :end_date, :section,
      :proprietary_sales, :proprietary_purchases, :proprietary_total, :proprietary_balance,
      :brokerage_sales, :brokerage_purchases, :brokerage_total, :brokerage_balance,
      :total_sales, :total_purchases, :total_total, :total_balance,
      :individuals_sales, :individuals_purchases, :individuals_total, :individuals_balance,
      :foreigners_sales, :foreigners_purchases, :foreigners_total, :foreigners_balance,
      :securities_cos_sales, :securities_cos_purchases, :securities_cos_total, :securities_cos_balance,
      :investment_trusts_sales, :investment_trusts_purchases, :investment_trusts_total, :investment_trusts_balance,
      :business_cos_sales, :business_cos_purchases, :business_cos_total, :business_cos_balance,
      :other_cos_sales, :other_cos_purchases, :other_cos_total, :other_cos_balance,
      :insurance_cos_sales, :insurance_cos_purchases, :insurance_cos_total, :insurance_cos_balance,
      :city_bks_regional_bks_etc_sales, :city_bks_regional_bks_etc_purchases, :city_bks_regional_bks_etc_total, :city_bks_regional_bks_etc_balance,
      :trust_banks_sales, :trust_banks_purchases, :trust_banks_total, :trust_banks_balance,
      :other_financial_institutions_sales, :other_financial_institutions_purchases, :other_financial_institutions_total, :other_financial_institutions_balance
    ])
    |> validate_required([
      :published_date, :start_date, :end_date, :section,
      :proprietary_sales, :proprietary_purchases, :proprietary_total, :proprietary_balance,
      :brokerage_sales, :brokerage_purchases, :brokerage_total, :brokerage_balance,
      :total_sales, :total_purchases, :total_total, :total_balance,
      :individuals_sales, :individuals_purchases, :individuals_total, :individuals_balance,
      :foreigners_sales, :foreigners_purchases, :foreigners_total, :foreigners_balance,
      :securities_cos_sales, :securities_cos_purchases, :securities_cos_total, :securities_cos_balance,
      :investment_trusts_sales, :investment_trusts_purchases, :investment_trusts_total, :investment_trusts_balance,
      :business_cos_sales, :business_cos_purchases, :business_cos_total, :business_cos_balance,
      :other_cos_sales, :other_cos_purchases, :other_cos_total, :other_cos_balance,
      :insurance_cos_sales, :insurance_cos_purchases, :insurance_cos_total, :insurance_cos_balance,
      :city_bks_regional_bks_etc_sales, :city_bks_regional_bks_etc_purchases, :city_bks_regional_bks_etc_total, :city_bks_regional_bks_etc_balance,
      :trust_banks_sales, :trust_banks_purchases, :trust_banks_total, :trust_banks_balance,
      :other_financial_institutions_sales, :other_financial_institutions_purchases, :other_financial_institutions_total, :other_financial_institutions_balance
    ])
    |> unique_constraint([:published_date, :start_date, :end_date, :section])
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

  defp make_request(%{credential: _credential, base_url: base_url}, id_token, section, from_date, to_date) do
    url = "#{base_url}/markets/trades_spec"
    params = %{
      section: section,
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

  defp parse_response(%{"trades_spec" => trades_specs}) do
    {:ok, Enum.map(trades_specs, &map_to_trades_spec/1)}
  end

  defp parse_response(_) do
    {:error, Error.error(:invalid_response, "Invalid response format")}
  end

  defp map_to_trades_spec(data) do
    %{
      published_date: Date.from_iso8601!(data["PublishedDate"]),
      start_date: Date.from_iso8601!(data["StartDate"]),
      end_date: Date.from_iso8601!(data["EndDate"]),
      section: data["Section"],
      # 自己計
      proprietary_sales: data["ProprietarySales"],
      proprietary_purchases: data["ProprietaryPurchases"],
      proprietary_total: data["ProprietaryTotal"],
      proprietary_balance: data["ProprietaryBalance"],
      # 委託計
      brokerage_sales: data["BrokerageSales"],
      brokerage_purchases: data["BrokeragePurchases"],
      brokerage_total: data["BrokerageTotal"],
      brokerage_balance: data["BrokerageBalance"],
      # 総計
      total_sales: data["TotalSales"],
      total_purchases: data["TotalPurchases"],
      total_total: data["TotalTotal"],
      total_balance: data["TotalBalance"],
      # 個人
      individuals_sales: data["IndividualsSales"],
      individuals_purchases: data["IndividualsPurchases"],
      individuals_total: data["IndividualsTotal"],
      individuals_balance: data["IndividualsBalance"],
      # 外国人
      foreigners_sales: data["ForeignersSales"],
      foreigners_purchases: data["ForeignersPurchases"],
      foreigners_total: data["ForeignersTotal"],
      foreigners_balance: data["ForeignersBalance"],
      # 証券会社
      securities_cos_sales: data["SecuritiesCosSales"],
      securities_cos_purchases: data["SecuritiesCosPurchases"],
      securities_cos_total: data["SecuritiesCosTotal"],
      securities_cos_balance: data["SecuritiesCosBalance"],
      # 投資信託
      investment_trusts_sales: data["InvestmentTrustsSales"],
      investment_trusts_purchases: data["InvestmentTrustsPurchases"],
      investment_trusts_total: data["InvestmentTrustsTotal"],
      investment_trusts_balance: data["InvestmentTrustsBalance"],
      # 事業法人
      business_cos_sales: data["BusinessCosSales"],
      business_cos_purchases: data["BusinessCosPurchases"],
      business_cos_total: data["BusinessCosTotal"],
      business_cos_balance: data["BusinessCosBalance"],
      # その他法人
      other_cos_sales: data["OtherCosSales"],
      other_cos_purchases: data["OtherCosPurchases"],
      other_cos_total: data["OtherCosTotal"],
      other_cos_balance: data["OtherCosBalance"],
      # 生保・損保
      insurance_cos_sales: data["InsuranceCosSales"],
      insurance_cos_purchases: data["InsuranceCosPurchases"],
      insurance_cos_total: data["InsuranceCosTotal"],
      insurance_cos_balance: data["InsuranceCosBalance"],
      # 都銀・地銀等
      city_bks_regional_bks_etc_sales: data["CityBKsRegionalBKsEtcSales"],
      city_bks_regional_bks_etc_purchases: data["CityBKsRegionalBKsEtcPurchases"],
      city_bks_regional_bks_etc_total: data["CityBKsRegionalBKsEtcTotal"],
      city_bks_regional_bks_etc_balance: data["CityBKsRegionalBKsEtcBalance"],
      # 信託銀行
      trust_banks_sales: data["TrustBanksSales"],
      trust_banks_purchases: data["TrustBanksPurchases"],
      trust_banks_total: data["TrustBanksTotal"],
      trust_banks_balance: data["TrustBanksBalance"],
      # その他金融機関
      other_financial_institutions_sales: data["OtherFinancialInstitutionsSales"],
      other_financial_institutions_purchases: data["OtherFinancialInstitutionsPurchases"],
      other_financial_institutions_total: data["OtherFinancialInstitutionsTotal"],
      other_financial_institutions_balance: data["OtherFinancialInstitutionsBalance"]
    }
  end

  defp save_trades_specs(trades_specs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    trades_specs_with_timestamps = Enum.map(trades_specs, fn spec ->
      Map.merge(spec, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      trades_specs_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:published_date, :start_date, :end_date, :section]
    )
    {:ok, %{count: count}}
  end
end
