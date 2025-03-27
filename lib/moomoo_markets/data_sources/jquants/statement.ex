defmodule MoomooMarkets.DataSources.JQuants.Statement do
  @moduledoc """
  J-Quants APIから財務情報を取得し、データベースに保存するモジュール
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, DocumentTypes}
  alias MoomooMarkets.Repo

  @type t :: %__MODULE__{
    # 基本情報フィールド
    disclosed_date: Date.t(),
    disclosed_time: String.t(),
    local_code: String.t(),
    disclosure_number: String.t(),
    type_of_document: String.t(),
    type_of_current_period: String.t(),
    current_period_start_date: Date.t() | nil,
    current_period_end_date: Date.t() | nil,
    current_fiscal_year_start_date: Date.t() | nil,
    current_fiscal_year_end_date: Date.t() | nil,
    next_fiscal_year_start_date: Date.t() | nil,
    next_fiscal_year_end_date: Date.t() | nil,

    # 主要財務指標
    net_sales: Decimal.t() | nil,
    operating_profit: Decimal.t() | nil,
    ordinary_profit: Decimal.t() | nil,
    profit: Decimal.t() | nil,
    earnings_per_share: Decimal.t() | nil,
    diluted_earnings_per_share: Decimal.t() | nil,
    total_assets: Decimal.t() | nil,
    equity: Decimal.t() | nil,
    equity_to_asset_ratio: Decimal.t() | nil,
    book_value_per_share: Decimal.t() | nil,

    # 予想値
    forecast_net_sales: Decimal.t() | nil,
    forecast_operating_profit: Decimal.t() | nil,
    forecast_ordinary_profit: Decimal.t() | nil,
    forecast_profit: Decimal.t() | nil,
    forecast_earnings_per_share: Decimal.t() | nil,

    # 次期予想値
    next_year_forecast_net_sales: Decimal.t() | nil,
    next_year_forecast_operating_profit: Decimal.t() | nil,
    next_year_forecast_ordinary_profit: Decimal.t() | nil,
    next_year_forecast_profit: Decimal.t() | nil,
    next_year_forecast_earnings_per_share: Decimal.t() | nil,

    # 非連結財務指標
    non_consolidated_net_sales: Decimal.t() | nil,
    non_consolidated_operating_profit: Decimal.t() | nil,
    non_consolidated_ordinary_profit: Decimal.t() | nil,
    non_consolidated_profit: Decimal.t() | nil,
    non_consolidated_earnings_per_share: Decimal.t() | nil,
    non_consolidated_total_assets: Decimal.t() | nil,
    non_consolidated_equity: Decimal.t() | nil,
    non_consolidated_equity_to_asset_ratio: Decimal.t() | nil,
    non_consolidated_book_value_per_share: Decimal.t() | nil,

    # 非連結予想値（期末）
    forecast_non_consolidated_net_sales: Decimal.t() | nil,
    forecast_non_consolidated_operating_profit: Decimal.t() | nil,
    forecast_non_consolidated_ordinary_profit: Decimal.t() | nil,
    forecast_non_consolidated_profit: Decimal.t() | nil,
    forecast_non_consolidated_earnings_per_share: Decimal.t() | nil,

    # 翌事業年度予想値（非連結）
    next_year_forecast_non_consolidated_net_sales: Decimal.t() | nil,
    next_year_forecast_non_consolidated_operating_profit: Decimal.t() | nil,
    next_year_forecast_non_consolidated_ordinary_profit: Decimal.t() | nil,
    next_year_forecast_non_consolidated_profit: Decimal.t() | nil,
    next_year_forecast_non_consolidated_earnings_per_share: Decimal.t() | nil,

    # 第2四半期予想値（非連結）
    forecast_non_consolidated_net_sales_2nd_quarter: Decimal.t() | nil,
    forecast_non_consolidated_operating_profit_2nd_quarter: Decimal.t() | nil,
    forecast_non_consolidated_ordinary_profit_2nd_quarter: Decimal.t() | nil,
    forecast_non_consolidated_profit_2nd_quarter: Decimal.t() | nil,
    forecast_non_consolidated_earnings_per_share_2nd_quarter: Decimal.t() | nil,

    # 翌事業年度第2四半期予想値（非連結）
    next_year_forecast_non_consolidated_net_sales_2nd_quarter: Decimal.t() | nil,
    next_year_forecast_non_consolidated_operating_profit_2nd_quarter: Decimal.t() | nil,
    next_year_forecast_non_consolidated_ordinary_profit_2nd_quarter: Decimal.t() | nil,
    next_year_forecast_non_consolidated_profit_2nd_quarter: Decimal.t() | nil,
    next_year_forecast_non_consolidated_earnings_per_share_2nd_quarter: Decimal.t() | nil,

    # 期中の変更に関する項目
    material_changes_in_subsidiaries: String.t() | nil,
    significant_changes_in_the_scope_of_consolidation: String.t() | nil,
    changes_based_on_revisions_of_accounting_standard: String.t() | nil,
    changes_other_than_ones_based_on_revisions_of_accounting_standard: String.t() | nil,
    changes_in_accounting_estimates: String.t() | nil,
    retrospective_restatement: String.t() | nil,

    # 株式数に関する項目
    number_of_issued_and_outstanding_shares_at_the_end_of_fiscal_year_including_treasury_stock: Decimal.t() | nil,
    number_of_treasury_stock_at_the_end_of_fiscal_year: Decimal.t() | nil,
    average_number_of_shares: Decimal.t() | nil,

    # タイムスタンプ
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "statements" do
    # 基本情報
    field :disclosed_date, :date
    field :disclosed_time, :string
    field :local_code, :string
    field :disclosure_number, :string
    field :type_of_document, :string
    field :type_of_current_period, :string
    field :current_period_start_date, :date
    field :current_period_end_date, :date
    field :current_fiscal_year_start_date, :date
    field :current_fiscal_year_end_date, :date
    field :next_fiscal_year_start_date, :date
    field :next_fiscal_year_end_date, :date

    # 主要財務指標
    field :net_sales, :decimal
    field :operating_profit, :decimal
    field :ordinary_profit, :decimal
    field :profit, :decimal
    field :earnings_per_share, :decimal
    field :diluted_earnings_per_share, :decimal
    field :total_assets, :decimal
    field :equity, :decimal
    field :equity_to_asset_ratio, :decimal
    field :book_value_per_share, :decimal

    # 予想値
    field :forecast_net_sales, :decimal
    field :forecast_operating_profit, :decimal
    field :forecast_ordinary_profit, :decimal
    field :forecast_profit, :decimal
    field :forecast_earnings_per_share, :decimal

    # 次期予想値
    field :next_year_forecast_net_sales, :decimal
    field :next_year_forecast_operating_profit, :decimal
    field :next_year_forecast_ordinary_profit, :decimal
    field :next_year_forecast_profit, :decimal
    field :next_year_forecast_earnings_per_share, :decimal

    # 非連結財務指標
    field :non_consolidated_net_sales, :decimal
    field :non_consolidated_operating_profit, :decimal
    field :non_consolidated_ordinary_profit, :decimal
    field :non_consolidated_profit, :decimal
    field :non_consolidated_earnings_per_share, :decimal
    field :non_consolidated_total_assets, :decimal
    field :non_consolidated_equity, :decimal
    field :non_consolidated_equity_to_asset_ratio, :decimal
    field :non_consolidated_book_value_per_share, :decimal

    # 非連結予想値（期末）
    field :forecast_non_consolidated_net_sales, :decimal
    field :forecast_non_consolidated_operating_profit, :decimal
    field :forecast_non_consolidated_ordinary_profit, :decimal
    field :forecast_non_consolidated_profit, :decimal
    field :forecast_non_consolidated_earnings_per_share, :decimal

    # 翌事業年度予想値（非連結）
    field :next_year_forecast_non_consolidated_net_sales, :decimal
    field :next_year_forecast_non_consolidated_operating_profit, :decimal
    field :next_year_forecast_non_consolidated_ordinary_profit, :decimal
    field :next_year_forecast_non_consolidated_profit, :decimal
    field :next_year_forecast_non_consolidated_earnings_per_share, :decimal

    # 第2四半期予想値（非連結）
    field :forecast_non_consolidated_net_sales_2nd_quarter, :decimal
    field :forecast_non_consolidated_operating_profit_2nd_quarter, :decimal
    field :forecast_non_consolidated_ordinary_profit_2nd_quarter, :decimal
    field :forecast_non_consolidated_profit_2nd_quarter, :decimal
    field :forecast_non_consolidated_earnings_per_share_2nd_quarter, :decimal

    # 翌事業年度第2四半期予想値（非連結）
    field :next_year_forecast_non_consolidated_net_sales_2nd_quarter, :decimal
    field :next_year_forecast_non_consolidated_operating_profit_2nd_quarter, :decimal
    field :next_year_forecast_non_consolidated_ordinary_profit_2nd_quarter, :decimal
    field :next_year_forecast_non_consolidated_profit_2nd_quarter, :decimal
    field :next_year_forecast_non_consolidated_earnings_per_share_2nd_quarter, :decimal

    # 期中の変更に関する項目
    field :material_changes_in_subsidiaries, :string
    field :significant_changes_in_the_scope_of_consolidation, :string
    field :changes_based_on_revisions_of_accounting_standard, :string
    field :changes_other_than_ones_based_on_revisions_of_accounting_standard, :string
    field :changes_in_accounting_estimates, :string
    field :retrospective_restatement, :string

    # 株式数に関する項目
    field :number_of_issued_and_outstanding_shares_at_the_end_of_fiscal_year_including_treasury_stock, :decimal
    field :number_of_treasury_stock_at_the_end_of_fiscal_year, :decimal
    field :average_number_of_shares, :decimal

    timestamps()
  end

  @doc """
  指定された銘柄コードの財務情報を取得します
  """
  @spec fetch_statements(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_statements(code, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_statements(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def changeset(statement, attrs) do
    statement
    |> cast(attrs, [
      # 基本情報
      :disclosed_date, :disclosed_time, :local_code, :disclosure_number,
      :type_of_document, :type_of_current_period,
      :current_period_start_date, :current_period_end_date,
      :current_fiscal_year_start_date, :current_fiscal_year_end_date,
      :next_fiscal_year_start_date, :next_fiscal_year_end_date,

      # 主要財務指標
      :net_sales, :operating_profit, :ordinary_profit, :profit,
      :earnings_per_share, :diluted_earnings_per_share,
      :total_assets, :equity, :equity_to_asset_ratio,
      :book_value_per_share,

      # 予想値
      :forecast_net_sales, :forecast_operating_profit,
      :forecast_ordinary_profit, :forecast_profit,
      :forecast_earnings_per_share,

      # 次期予想値
      :next_year_forecast_net_sales, :next_year_forecast_operating_profit,
      :next_year_forecast_ordinary_profit, :next_year_forecast_profit,
      :next_year_forecast_earnings_per_share,

      # 非連結財務指標
      :non_consolidated_net_sales, :non_consolidated_operating_profit,
      :non_consolidated_ordinary_profit, :non_consolidated_profit,
      :non_consolidated_earnings_per_share, :non_consolidated_total_assets,
      :non_consolidated_equity, :non_consolidated_equity_to_asset_ratio,
      :non_consolidated_book_value_per_share,

      # 非連結予想値（期末）
      :forecast_non_consolidated_net_sales, :forecast_non_consolidated_operating_profit,
      :forecast_non_consolidated_ordinary_profit, :forecast_non_consolidated_profit,
      :forecast_non_consolidated_earnings_per_share,

      # 翌事業年度予想値（非連結）
      :next_year_forecast_non_consolidated_net_sales,
      :next_year_forecast_non_consolidated_operating_profit,
      :next_year_forecast_non_consolidated_ordinary_profit,
      :next_year_forecast_non_consolidated_profit,
      :next_year_forecast_non_consolidated_earnings_per_share,

      # 第2四半期予想値（非連結）
      :forecast_non_consolidated_net_sales_2nd_quarter,
      :forecast_non_consolidated_operating_profit_2nd_quarter,
      :forecast_non_consolidated_ordinary_profit_2nd_quarter,
      :forecast_non_consolidated_profit_2nd_quarter,
      :forecast_non_consolidated_earnings_per_share_2nd_quarter,

      # 翌事業年度第2四半期予想値（非連結）
      :next_year_forecast_non_consolidated_net_sales_2nd_quarter,
      :next_year_forecast_non_consolidated_operating_profit_2nd_quarter,
      :next_year_forecast_non_consolidated_ordinary_profit_2nd_quarter,
      :next_year_forecast_non_consolidated_profit_2nd_quarter,
      :next_year_forecast_non_consolidated_earnings_per_share_2nd_quarter,

      # 期中の変更に関する項目
      :material_changes_in_subsidiaries,
      :significant_changes_in_the_scope_of_consolidation,
      :changes_based_on_revisions_of_accounting_standard,
      :changes_other_than_ones_based_on_revisions_of_accounting_standard,
      :changes_in_accounting_estimates,
      :retrospective_restatement,

      # 株式数に関する項目
      :number_of_issued_and_outstanding_shares_at_the_end_of_fiscal_year_including_treasury_stock,
      :number_of_treasury_stock_at_the_end_of_fiscal_year,
      :average_number_of_shares
    ])
    |> validate_required([
      :disclosed_date,
      :local_code,
      :disclosure_number,
      :type_of_document,
      :type_of_current_period
    ])
    |> validate_inclusion(:type_of_document, DocumentTypes.all_types())
    |> unique_constraint(:disclosure_number)
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
    url = "#{base_url}/fins/statements"
    params = %{
      code: code,
      from: Date.to_iso8601(from_date),
      to: Date.to_iso8601(to_date)
    }
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: %{"message" => message}}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status, message: message})}
      {:ok, %{status: status}} ->
        {:error, Error.error(:api_error, "API request failed", %{status: status})}
      {:error, %{reason: reason}} ->
        {:error, Error.error(:http_error, "HTTP request failed", %{reason: reason})}
    end
  end

  defp parse_response(%{"statements" => statements}) do
    {:ok, Enum.map(statements, &map_to_statement/1)}
  end

  defp parse_response(_), do: {:error, Error.error(:invalid_response, "Invalid response format")}

  defp map_to_statement(data) do
    %{
      # 基本情報
      disclosed_date: data["DisclosedDate"] && Date.from_iso8601!(data["DisclosedDate"]),
      disclosed_time: data["DisclosedTime"],
      local_code: data["LocalCode"],
      disclosure_number: data["DisclosureNumber"],
      type_of_document: data["TypeOfDocument"],
      type_of_current_period: data["TypeOfCurrentPeriod"],
      current_period_start_date: (data["CurrentPeriodStartDate"] && data["CurrentPeriodStartDate"] != "" && Date.from_iso8601!(data["CurrentPeriodStartDate"])) || nil,
      current_period_end_date: (data["CurrentPeriodEndDate"] && data["CurrentPeriodEndDate"] != "" && Date.from_iso8601!(data["CurrentPeriodEndDate"])) || nil,
      current_fiscal_year_start_date: (data["CurrentFiscalYearStartDate"] && data["CurrentFiscalYearStartDate"] != "" && Date.from_iso8601!(data["CurrentFiscalYearStartDate"])) || nil,
      current_fiscal_year_end_date: (data["CurrentFiscalYearEndDate"] && data["CurrentFiscalYearEndDate"] != "" && Date.from_iso8601!(data["CurrentFiscalYearEndDate"])) || nil,
      next_fiscal_year_start_date: (data["NextFiscalYearStartDate"] && data["NextFiscalYearStartDate"] != "" && Date.from_iso8601!(data["NextFiscalYearStartDate"])) || nil,
      next_fiscal_year_end_date: (data["NextFiscalYearEndDate"] && data["NextFiscalYearEndDate"] != "" && Date.from_iso8601!(data["NextFiscalYearEndDate"])) || nil,

      # 主要財務指標
      net_sales: (data["NetSales"] && data["NetSales"] != "" && Decimal.new("#{data["NetSales"]}")) || nil,
      operating_profit: (data["OperatingProfit"] && data["OperatingProfit"] != "" && Decimal.new("#{data["OperatingProfit"]}")) || nil,
      ordinary_profit: (data["OrdinaryProfit"] && data["OrdinaryProfit"] != "" && Decimal.new("#{data["OrdinaryProfit"]}")) || nil,
      profit: (data["Profit"] && data["Profit"] != "" && Decimal.new("#{data["Profit"]}")) || nil,
      earnings_per_share: (data["EarningsPerShare"] && data["EarningsPerShare"] != "" && Decimal.new("#{data["EarningsPerShare"]}")) || nil,
      diluted_earnings_per_share: (data["DilutedEarningsPerShare"] && data["DilutedEarningsPerShare"] != "" && Decimal.new("#{data["DilutedEarningsPerShare"]}")) || nil,
      total_assets: (data["TotalAssets"] && data["TotalAssets"] != "" && Decimal.new("#{data["TotalAssets"]}")) || nil,
      equity: (data["Equity"] && data["Equity"] != "" && Decimal.new("#{data["Equity"]}")) || nil,
      equity_to_asset_ratio: (data["EquityToAssetRatio"] && data["EquityToAssetRatio"] != "" && Decimal.new("#{data["EquityToAssetRatio"]}")) || nil,
      book_value_per_share: (data["BookValuePerShare"] && data["BookValuePerShare"] != "" && Decimal.new("#{data["BookValuePerShare"]}")) || nil,

      # 予想値
      forecast_net_sales: (data["ForecastNetSales"] && data["ForecastNetSales"] != "" && Decimal.new("#{data["ForecastNetSales"]}")) || nil,
      forecast_operating_profit: (data["ForecastOperatingProfit"] && data["ForecastOperatingProfit"] != "" && Decimal.new("#{data["ForecastOperatingProfit"]}")) || nil,
      forecast_ordinary_profit: (data["ForecastOrdinaryProfit"] && data["ForecastOrdinaryProfit"] != "" && Decimal.new("#{data["ForecastOrdinaryProfit"]}")) || nil,
      forecast_profit: (data["ForecastProfit"] && data["ForecastProfit"] != "" && Decimal.new("#{data["ForecastProfit"]}")) || nil,
      forecast_earnings_per_share: (data["ForecastEarningsPerShare"] && data["ForecastEarningsPerShare"] != "" && Decimal.new("#{data["ForecastEarningsPerShare"]}")) || nil,

      # 次期予想値
      next_year_forecast_net_sales: (data["NextYearForecastNetSales"] && data["NextYearForecastNetSales"] != "" && Decimal.new("#{data["NextYearForecastNetSales"]}")) || nil,
      next_year_forecast_operating_profit: (data["NextYearForecastOperatingProfit"] && data["NextYearForecastOperatingProfit"] != "" && Decimal.new("#{data["NextYearForecastOperatingProfit"]}")) || nil,
      next_year_forecast_ordinary_profit: (data["NextYearForecastOrdinaryProfit"] && data["NextYearForecastOrdinaryProfit"] != "" && Decimal.new("#{data["NextYearForecastOrdinaryProfit"]}")) || nil,
      next_year_forecast_profit: (data["NextYearForecastProfit"] && data["NextYearForecastProfit"] != "" && Decimal.new("#{data["NextYearForecastProfit"]}")) || nil,
      next_year_forecast_earnings_per_share: (data["NextYearForecastEarningsPerShare"] && data["NextYearForecastEarningsPerShare"] != "" && Decimal.new("#{data["NextYearForecastEarningsPerShare"]}")) || nil,

      # 非連結財務指標
      non_consolidated_net_sales: (data["NonConsolidatedNetSales"] && data["NonConsolidatedNetSales"] != "" && Decimal.new("#{data["NonConsolidatedNetSales"]}")) || nil,
      non_consolidated_operating_profit: (data["NonConsolidatedOperatingProfit"] && data["NonConsolidatedOperatingProfit"] != "" && Decimal.new("#{data["NonConsolidatedOperatingProfit"]}")) || nil,
      non_consolidated_ordinary_profit: (data["NonConsolidatedOrdinaryProfit"] && data["NonConsolidatedOrdinaryProfit"] != "" && Decimal.new("#{data["NonConsolidatedOrdinaryProfit"]}")) || nil,
      non_consolidated_profit: (data["NonConsolidatedProfit"] && data["NonConsolidatedProfit"] != "" && Decimal.new("#{data["NonConsolidatedProfit"]}")) || nil,
      non_consolidated_earnings_per_share: (data["NonConsolidatedEarningsPerShare"] && data["NonConsolidatedEarningsPerShare"] != "" && Decimal.new("#{data["NonConsolidatedEarningsPerShare"]}")) || nil,
      non_consolidated_total_assets: (data["NonConsolidatedTotalAssets"] && data["NonConsolidatedTotalAssets"] != "" && Decimal.new("#{data["NonConsolidatedTotalAssets"]}")) || nil,
      non_consolidated_equity: (data["NonConsolidatedEquity"] && data["NonConsolidatedEquity"] != "" && Decimal.new("#{data["NonConsolidatedEquity"]}")) || nil,
      non_consolidated_equity_to_asset_ratio: (data["NonConsolidatedEquityToAssetRatio"] && data["NonConsolidatedEquityToAssetRatio"] != "" && Decimal.new("#{data["NonConsolidatedEquityToAssetRatio"]}")) || nil,
      non_consolidated_book_value_per_share: (data["NonConsolidatedBookValuePerShare"] && data["NonConsolidatedBookValuePerShare"] != "" && Decimal.new("#{data["NonConsolidatedBookValuePerShare"]}")) || nil,

      # 非連結予想値（期末）
      forecast_non_consolidated_net_sales: (data["ForecastNonConsolidatedNetSales"] && data["ForecastNonConsolidatedNetSales"] != "" && Decimal.new("#{data["ForecastNonConsolidatedNetSales"]}")) || nil,
      forecast_non_consolidated_operating_profit: (data["ForecastNonConsolidatedOperatingProfit"] && data["ForecastNonConsolidatedOperatingProfit"] != "" && Decimal.new("#{data["ForecastNonConsolidatedOperatingProfit"]}")) || nil,
      forecast_non_consolidated_ordinary_profit: (data["ForecastNonConsolidatedOrdinaryProfit"] && data["ForecastNonConsolidatedOrdinaryProfit"] != "" && Decimal.new("#{data["ForecastNonConsolidatedOrdinaryProfit"]}")) || nil,
      forecast_non_consolidated_profit: (data["ForecastNonConsolidatedProfit"] && data["ForecastNonConsolidatedProfit"] != "" && Decimal.new("#{data["ForecastNonConsolidatedProfit"]}")) || nil,
      forecast_non_consolidated_earnings_per_share: (data["ForecastNonConsolidatedEarningsPerShare"] && data["ForecastNonConsolidatedEarningsPerShare"] != "" && Decimal.new("#{data["ForecastNonConsolidatedEarningsPerShare"]}")) || nil,

      # 翌事業年度予想値（非連結）
      next_year_forecast_non_consolidated_net_sales: (data["NextYearForecastNonConsolidatedNetSales"] && data["NextYearForecastNonConsolidatedNetSales"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedNetSales"]}")) || nil,
      next_year_forecast_non_consolidated_operating_profit: (data["NextYearForecastNonConsolidatedOperatingProfit"] && data["NextYearForecastNonConsolidatedOperatingProfit"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedOperatingProfit"]}")) || nil,
      next_year_forecast_non_consolidated_ordinary_profit: (data["NextYearForecastNonConsolidatedOrdinaryProfit"] && data["NextYearForecastNonConsolidatedOrdinaryProfit"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedOrdinaryProfit"]}")) || nil,
      next_year_forecast_non_consolidated_profit: (data["NextYearForecastNonConsolidatedProfit"] && data["NextYearForecastNonConsolidatedProfit"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedProfit"]}")) || nil,
      next_year_forecast_non_consolidated_earnings_per_share: (data["NextYearForecastNonConsolidatedEarningsPerShare"] && data["NextYearForecastNonConsolidatedEarningsPerShare"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedEarningsPerShare"]}")) || nil,

      # 第2四半期予想値（非連結）
      forecast_non_consolidated_net_sales_2nd_quarter: (data["ForecastNonConsolidatedNetSales2ndQuarter"] && data["ForecastNonConsolidatedNetSales2ndQuarter"] != "" && Decimal.new("#{data["ForecastNonConsolidatedNetSales2ndQuarter"]}")) || nil,
      forecast_non_consolidated_operating_profit_2nd_quarter: (data["ForecastNonConsolidatedOperatingProfit2ndQuarter"] && data["ForecastNonConsolidatedOperatingProfit2ndQuarter"] != "" && Decimal.new("#{data["ForecastNonConsolidatedOperatingProfit2ndQuarter"]}")) || nil,
      forecast_non_consolidated_ordinary_profit_2nd_quarter: (data["ForecastNonConsolidatedOrdinaryProfit2ndQuarter"] && data["ForecastNonConsolidatedOrdinaryProfit2ndQuarter"] != "" && Decimal.new("#{data["ForecastNonConsolidatedOrdinaryProfit2ndQuarter"]}")) || nil,
      forecast_non_consolidated_profit_2nd_quarter: (data["ForecastNonConsolidatedProfit2ndQuarter"] && data["ForecastNonConsolidatedProfit2ndQuarter"] != "" && Decimal.new("#{data["ForecastNonConsolidatedProfit2ndQuarter"]}")) || nil,
      forecast_non_consolidated_earnings_per_share_2nd_quarter: (data["ForecastNonConsolidatedEarningsPerShare2ndQuarter"] && data["ForecastNonConsolidatedEarningsPerShare2ndQuarter"] != "" && Decimal.new("#{data["ForecastNonConsolidatedEarningsPerShare2ndQuarter"]}")) || nil,

      # 翌事業年度第2四半期予想値（非連結）
      next_year_forecast_non_consolidated_net_sales_2nd_quarter: (data["NextYearForecastNonConsolidatedNetSales2ndQuarter"] && data["NextYearForecastNonConsolidatedNetSales2ndQuarter"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedNetSales2ndQuarter"]}")) || nil,
      next_year_forecast_non_consolidated_operating_profit_2nd_quarter: (data["NextYearForecastNonConsolidatedOperatingProfit2ndQuarter"] && data["NextYearForecastNonConsolidatedOperatingProfit2ndQuarter"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedOperatingProfit2ndQuarter"]}")) || nil,
      next_year_forecast_non_consolidated_ordinary_profit_2nd_quarter: (data["NextYearForecastNonConsolidatedOrdinaryProfit2ndQuarter"] && data["NextYearForecastNonConsolidatedOrdinaryProfit2ndQuarter"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedOrdinaryProfit2ndQuarter"]}")) || nil,
      next_year_forecast_non_consolidated_profit_2nd_quarter: (data["NextYearForecastNonConsolidatedProfit2ndQuarter"] && data["NextYearForecastNonConsolidatedProfit2ndQuarter"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedProfit2ndQuarter"]}")) || nil,
      next_year_forecast_non_consolidated_earnings_per_share_2nd_quarter: (data["NextYearForecastNonConsolidatedEarningsPerShare2ndQuarter"] && data["NextYearForecastNonConsolidatedEarningsPerShare2ndQuarter"] != "" && Decimal.new("#{data["NextYearForecastNonConsolidatedEarningsPerShare2ndQuarter"]}")) || nil,

      # 期中の変更に関する項目
      material_changes_in_subsidiaries: data["MaterialChangesInSubsidiaries"],
      significant_changes_in_the_scope_of_consolidation: data["SignificantChangesInTheScopeOfConsolidation"],
      changes_based_on_revisions_of_accounting_standard: data["ChangesBasedOnRevisionsOfAccountingStandard"],
      changes_other_than_ones_based_on_revisions_of_accounting_standard: data["ChangesOtherThanOnesBasedOnRevisionsOfAccountingStandard"],
      changes_in_accounting_estimates: data["ChangesInAccountingEstimates"],
      retrospective_restatement: data["RetrospectiveRestatement"],

      # 株式数に関する項目
      number_of_issued_and_outstanding_shares_at_the_end_of_fiscal_year_including_treasury_stock: (data["NumberOfIssuedAndOutstandingSharesAtTheEndOfFiscalYearIncludingTreasuryStock"] && data["NumberOfIssuedAndOutstandingSharesAtTheEndOfFiscalYearIncludingTreasuryStock"] != "" && Decimal.new("#{data["NumberOfIssuedAndOutstandingSharesAtTheEndOfFiscalYearIncludingTreasuryStock"]}")) || nil,
      number_of_treasury_stock_at_the_end_of_fiscal_year: (data["NumberOfTreasuryStockAtTheEndOfFiscalYear"] && data["NumberOfTreasuryStockAtTheEndOfFiscalYear"] != "" && Decimal.new("#{data["NumberOfTreasuryStockAtTheEndOfFiscalYear"]}")) || nil,
      average_number_of_shares: (data["AverageNumberOfShares"] && data["AverageNumberOfShares"] != "" && Decimal.new("#{data["AverageNumberOfShares"]}")) || nil
    }
  end

  defp save_statements(statements) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    statements_with_timestamps = Enum.map(statements, fn stmt ->
      Map.merge(stmt, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {count, _} = Repo.insert_all(
      __MODULE__,
      statements_with_timestamps,
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:disclosure_number]
    )
    {:ok, %{count: count}}
  end
end
