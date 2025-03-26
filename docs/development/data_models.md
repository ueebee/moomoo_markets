# データモデル設計

## 株価データ (Stock Prices)

### 概要
株価データは、J-Quants APIから取得し、データベースに保存します。
現在は基本機能のみを実装しており、Premiumプラン機能（前場/後場データ）は今後の拡張予定です。

### スキーマ定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.StockPrice do
  use Ecto.Schema
  import Ecto.Changeset

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
end
```

### マイグレーション
```elixir
defmodule MoomooMarkets.Repo.Migrations.CreateStockPrices do
  use Ecto.Migration

  def change do
    create table(:stock_prices) do
      add :code, :string, null: false
      add :date, :date, null: false
      add :open, :float, null: false
      add :high, :float, null: false
      add :low, :float, null: false
      add :close, :float, null: false
      add :volume, :float, null: false
      add :turnover_value, :float, null: false
      add :adjustment_factor, :float, null: false
      add :adjustment_open, :float, null: false
      add :adjustment_high, :float, null: false
      add :adjustment_low, :float, null: false
      add :adjustment_close, :float, null: false
      add :adjustment_volume, :float, null: false

      timestamps()
    end

    create unique_index(:stock_prices, [:code, :date])
    create index(:stock_prices, [:code])
    create index(:stock_prices, [:date])
  end
end
```

### データ取得モジュール
```elixir
defmodule MoomooMarkets.DataSources.JQuants.StockPrice do
  use Ecto.Schema
  import Ecto.Changeset
  alias MoomooMarkets.DataSources.JQuants.{Types, Error}

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
  指定された銘柄コードの株価データを取得します。
  """
  @spec fetch_stock_prices(String.t(), Date.t(), Date.t()) :: {:ok, list(t())} | {:error, Error.t()}
  def fetch_stock_prices(code, from_date, to_date) do
    with {:ok, credential} <- get_credential(),
         {:ok, response} <- make_request(credential, code, from_date, to_date),
         {:ok, stock_prices} <- parse_response(response) do
      save_stock_prices(stock_prices)
    end
  end

  @doc """
  指定された日付の全銘柄の株価データを取得します。
  """
  @spec fetch_all_stock_prices(Date.t()) :: {:ok, list(t())} | {:error, Error.t()}
  def fetch_all_stock_prices(date) do
    with {:ok, stocks} <- Stock.fetch_listed_info(),
         stock_prices <- Enum.map(stocks, fn stock ->
           fetch_stock_prices(stock.code, date, date)
         end) do
      {:ok, Enum.filter(stock_prices, fn
        {:ok, _} -> true
        {:error, _} -> false
      end)}
    end
  end

  defp get_credential do
    Types.get_credential()
  end

  defp make_request(credential, code, from_date, to_date) do
    url = "https://api.jquants.com/v1/prices/daily_quotes"
    params = %{
      code: code,
      from: Date.to_iso8601(from_date),
      to: Date.to_iso8601(to_date)
    }

    case Req.get(url, params: params, headers: [{"Authorization", "Bearer #{credential.refresh_token}"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, Error.error(:api_error, "API request failed with status #{status}", body)}

      {:error, error} ->
        {:error, Error.error(:http_error, "HTTP request failed", error)}
    end
  end

  defp parse_response(response) do
    case response do
      %{"daily_quotes" => quotes} when is_list(quotes) ->
        {:ok, Enum.map(quotes, &map_to_stock_price/1)}

      _ ->
        {:error, Error.error(:invalid_response, "Invalid response format", response)}
    end
  end

  defp map_to_stock_price(quote) do
    %{
      code: quote["code"],
      date: Date.from_iso8601!(quote["date"]),
      open: quote["open"],
      high: quote["high"],
      low: quote["low"],
      close: quote["close"],
      volume: quote["volume"],
      turnover_value: quote["turnover_value"],
      adjustment_factor: quote["adjustment_factor"],
      adjustment_open: quote["adjustment_open"],
      adjustment_high: quote["adjustment_high"],
      adjustment_low: quote["adjustment_low"],
      adjustment_close: quote["adjustment_close"],
      adjustment_volume: quote["adjustment_volume"]
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
```

### 考慮事項

1. **データの重複**
   - 銘柄コードと日付の組み合わせでユニーク制約を設定
   - 既存データの更新処理の実装

2. **エラーハンドリング**
   - APIエラーの適切な処理
   - データの欠損や不正な値の処理

3. **パフォーマンス**
   - バッチ処理の実装
   - インデックスの適切な設定

### 実装の優先順位

1. マイグレーションファイルの作成と実行
2. スキーマの実装
3. データ取得モジュールの実装
   - 認証処理
   - APIリクエスト
   - レスポンスのパース
   - データの保存
4. テストの実装
   - 正常系テスト
   - エラー系テスト
   - データマッピングテスト

### 将来の拡張予定

1. **Premiumプラン対応**
   - 前場/後場データの取得と保存
   - 以下のフィールドを追加予定：
     - morning_open, morning_high, morning_low, morning_close
     - morning_volume, morning_turnover_value
     - afternoon_open, afternoon_high, afternoon_low, afternoon_close
     - afternoon_volume, afternoon_turnover_value
   - プランに応じたデータ取得の制御
   - マイグレーションによる既存テーブルの拡張

#### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.StockPrice
alias MoomooMarkets.Repo

# 特定の銘柄の株価データを取得（例：86970）
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
StockPrice.fetch_stock_prices("86970", from_date, to_date)

# 特定の日付の全銘柄の株価データを取得
date = ~D[2024-03-25]
StockPrice.fetch_all_stock_prices(date)

# 保存されたデータの確認
Repo.all(StockPrice)
```

## 投資部門別売買状況 (Trades Specification)

### 概要
投資部門別売買状況は、J-Quants APIから取得し、データベースに保存します。
市場区分ごとの投資部門（個人、外国人、機関投資家など）の売買状況を記録します。

### スキーマ定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.TradesSpec do
  use Ecto.Schema
  import Ecto.Changeset

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

  @type market_section :: "TSEPrime" | "TSEStandard" | "TSEContinuous" | "TSE1st" | "TSE2nd" | "TSEJASDAQ" | "TSEJASDAQStandard" | "TSEJASDAQGrowth"

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
    |> validate_inclusion(:section, @market_sections)
    |> unique_constraint([:published_date, :start_date, :end_date, :section])
  end
end
```

### マイグレーション
```elixir
defmodule MoomooMarkets.Repo.Migrations.CreateTradesSpecs do
  use Ecto.Migration

  def change do
    create table(:trades_specs) do
      add :published_date, :date, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :section, :string, null: false
      # 自己計
      add :proprietary_sales, :float, null: false
      add :proprietary_purchases, :float, null: false
      add :proprietary_total, :float, null: false
      add :proprietary_balance, :float, null: false
      # 委託計
      add :brokerage_sales, :float, null: false
      add :brokerage_purchases, :float, null: false
      add :brokerage_total, :float, null: false
      add :brokerage_balance, :float, null: false
      # 総計
      add :total_sales, :float, null: false
      add :total_purchases, :float, null: false
      add :total_total, :float, null: false
      add :total_balance, :float, null: false
      # 個人
      add :individuals_sales, :float, null: false
      add :individuals_purchases, :float, null: false
      add :individuals_total, :float, null: false
      add :individuals_balance, :float, null: false
      # 外国人
      add :foreigners_sales, :float, null: false
      add :foreigners_purchases, :float, null: false
      add :foreigners_total, :float, null: false
      add :foreigners_balance, :float, null: false
      # 証券会社
      add :securities_cos_sales, :float, null: false
      add :securities_cos_purchases, :float, null: false
      add :securities_cos_total, :float, null: false
      add :securities_cos_balance, :float, null: false
      # 投資信託
      add :investment_trusts_sales, :float, null: false
      add :investment_trusts_purchases, :float, null: false
      add :investment_trusts_total, :float, null: false
      add :investment_trusts_balance, :float, null: false
      # 事業法人
      add :business_cos_sales, :float, null: false
      add :business_cos_purchases, :float, null: false
      add :business_cos_total, :float, null: false
      add :business_cos_balance, :float, null: false
      # その他法人
      add :other_cos_sales, :float, null: false
      add :other_cos_purchases, :float, null: false
      add :other_cos_total, :float, null: false
      add :other_cos_balance, :float, null: false
      # 生保・損保
      add :insurance_cos_sales, :float, null: false
      add :insurance_cos_purchases, :float, null: false
      add :insurance_cos_total, :float, null: false
      add :insurance_cos_balance, :float, null: false
      # 都銀・地銀等
      add :city_bks_regional_bks_etc_sales, :float, null: false
      add :city_bks_regional_bks_etc_purchases, :float, null: false
      add :city_bks_regional_bks_etc_total, :float, null: false
      add :city_bks_regional_bks_etc_balance, :float, null: false
      # 信託銀行
      add :trust_banks_sales, :float, null: false
      add :trust_banks_purchases, :float, null: false
      add :trust_banks_total, :float, null: false
      add :trust_banks_balance, :float, null: false
      # その他金融機関
      add :other_financial_institutions_sales, :float, null: false
      add :other_financial_institutions_purchases, :float, null: false
      add :other_financial_institutions_total, :float, null: false
      add :other_financial_institutions_balance, :float, null: false

      timestamps()
    end

    create unique_index(:trades_specs, [:published_date, :start_date, :end_date, :section])
    create index(:trades_specs, [:published_date])
    create index(:trades_specs, [:start_date])
    create index(:trades_specs, [:end_date])
    create index(:trades_specs, [:section])
  end
end
```

### データ取得モジュール
```elixir
defmodule MoomooMarkets.DataSources.JQuants.TradesSpec do
  use Ecto.Schema
  import Ecto.Changeset
  alias MoomooMarkets.DataSources.JQuants.{Types, Error}

  @doc """
  指定された市場区分の投資部門別売買状況を取得します。
  """
  @spec fetch_trades_spec(String.t(), Date.t(), Date.t()) :: {:ok, list(t())} | {:error, Error.t()}
  def fetch_trades_spec(section, from_date, to_date) do
    with {:ok, credential} <- get_credential(),
         {:ok, response} <- make_request(credential, section, from_date, to_date),
         {:ok, trades_specs} <- parse_response(response) do
      save_trades_specs(trades_specs)
    end
  end

  defp get_credential do
    Types.get_credential()
  end

  defp make_request(credential, section, from_date, to_date) do
    url = "https://api.jquants.com/v1/markets/trades_spec"
    params = %{
      section: section,
      from: Date.to_iso8601(from_date),
      to: Date.to_iso8601(to_date)
    }

    case Req.get(url, params: params, headers: [{"Authorization", "Bearer #{credential.refresh_token}"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, Error.error(:api_error, "API request failed with status #{status}", body)}

      {:error, error} ->
        {:error, Error.error(:http_error, "HTTP request failed", error)}
    end
  end

  defp parse_response(response) do
    case response do
      %{"trades_spec" => specs} when is_list(specs) ->
        {:ok, Enum.map(specs, &map_to_trades_spec/1)}

      _ ->
        {:error, Error.error(:invalid_response, "Invalid response format", response)}
    end
  end

  defp map_to_trades_spec(spec) do
    %{
      published_date: Date.from_iso8601!(spec["PublishedDate"]),
      start_date: Date.from_iso8601!(spec["StartDate"]),
      end_date: Date.from_iso8601!(spec["EndDate"]),
      section: spec["Section"],
      # 自己計
      proprietary_sales: spec["ProprietarySales"],
      proprietary_purchases: spec["ProprietaryPurchases"],
      proprietary_total: spec["ProprietaryTotal"],
      proprietary_balance: spec["ProprietaryBalance"],
      # 委託計
      brokerage_sales: spec["BrokerageSales"],
      brokerage_purchases: spec["BrokeragePurchases"],
      brokerage_total: spec["BrokerageTotal"],
      brokerage_balance: spec["BrokerageBalance"],
      # 総計
      total_sales: spec["TotalSales"],
      total_purchases: spec["TotalPurchases"],
      total_total: spec["TotalTotal"],
      total_balance: spec["TotalBalance"],
      # 個人
      individuals_sales: spec["IndividualsSales"],
      individuals_purchases: spec["IndividualsPurchases"],
      individuals_total: spec["IndividualsTotal"],
      individuals_balance: spec["IndividualsBalance"],
      # 外国人
      foreigners_sales: spec["ForeignersSales"],
      foreigners_purchases: spec["ForeignersPurchases"],
      foreigners_total: spec["ForeignersTotal"],
      foreigners_balance: spec["ForeignersBalance"],
      # 証券会社
      securities_cos_sales: spec["SecuritiesCosSales"],
      securities_cos_purchases: spec["SecuritiesCosPurchases"],
      securities_cos_total: spec["SecuritiesCosTotal"],
      securities_cos_balance: spec["SecuritiesCosBalance"],
      # 投資信託
      investment_trusts_sales: spec["InvestmentTrustsSales"],
      investment_trusts_purchases: spec["InvestmentTrustsPurchases"],
      investment_trusts_total: spec["InvestmentTrustsTotal"],
      investment_trusts_balance: spec["InvestmentTrustsBalance"],
      # 事業法人
      business_cos_sales: spec["BusinessCosSales"],
      business_cos_purchases: spec["BusinessCosPurchases"],
      business_cos_total: spec["BusinessCosTotal"],
      business_cos_balance: spec["BusinessCosBalance"],
      # その他法人
      other_cos_sales: spec["OtherCosSales"],
      other_cos_purchases: spec["OtherCosPurchases"],
      other_cos_total: spec["OtherCosTotal"],
      other_cos_balance: spec["OtherCosBalance"],
      # 生保・損保
      insurance_cos_sales: spec["InsuranceCosSales"],
      insurance_cos_purchases: spec["InsuranceCosPurchases"],
      insurance_cos_total: spec["InsuranceCosTotal"],
      insurance_cos_balance: spec["InsuranceCosBalance"],
      # 都銀・地銀等
      city_bks_regional_bks_etc_sales: spec["CityBKsRegionalBKsEtcSales"],
      city_bks_regional_bks_etc_purchases: spec["CityBKsRegionalBKsEtcPurchases"],
      city_bks_regional_bks_etc_total: spec["CityBKsRegionalBKsEtcTotal"],
      city_bks_regional_bks_etc_balance: spec["CityBKsRegionalBKsEtcBalance"],
      # 信託銀行
      trust_banks_sales: spec["TrustBanksSales"],
      trust_banks_purchases: spec["TrustBanksPurchases"],
      trust_banks_total: spec["TrustBanksTotal"],
      trust_banks_balance: spec["TrustBanksBalance"],
      # その他金融機関
      other_financial_institutions_sales: spec["OtherFinancialInstitutionsSales"],
      other_financial_institutions_purchases: spec["OtherFinancialInstitutionsPurchases"],
      other_financial_institutions_total: spec["OtherFinancialInstitutionsTotal"],
      other_financial_institutions_balance: spec["OtherFinancialInstitutionsBalance"]
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
```

### 考慮事項

1. **データの重複**
   - 公表日、開始日、終了日、市場区分の組み合わせでユニーク制約を設定
   - 既存データの更新処理の実装

2. **エラーハンドリング**
   - APIエラーの適切な処理
   - データの欠損や不正な値の処理
   - 過誤訂正データの処理（2023年4月3日以降のデータ）

3. **パフォーマンス**
   - インデックスの適切な設定
   - 大量データ取得時の処理

### 過誤訂正データの処理方針

#### 概要
J-Quants APIの仕様に基づき、2023年4月3日以降の過誤訂正データは以下のように処理します：
- 訂正前と訂正後のデータを両方保持
- 公表日で訂正前後を識別（公表日が新しいデータが訂正後）

#### データ構造
- 公表日（`published_date`）、開始日（`start_date`）、終了日（`end_date`）、市場区分（`section`）の組み合わせでユニーク制約を設定
- 訂正データは別レコードとして保存され、公表日で区別可能

#### データ取得
```elixir
# 最新データのみを取得（デフォルト）
TradesSpec.fetch_trades_spec("TSEPrime", from_date, to_date)

# 訂正履歴を含めて取得
TradesSpec.fetch_trades_spec("TSEPrime", from_date, to_date, latest_only: false)
```

#### データの集計
```elixir
# 特定の期間の最新データを取得
Repo.all(from t in TradesSpec,
  where: t.start_date >= ^from_date and t.end_date <= ^to_date,
  order_by: [desc: t.published_date],
  distinct: [t.start_date, t.end_date, t.section]
)

# 訂正履歴を含めて取得
Repo.all(from t in TradesSpec,
  where: t.start_date >= ^from_date and t.end_date <= ^to_date,
  order_by: [desc: t.published_date]
)
```

#### 考慮事項
1. **データの完全性**
   - 訂正履歴を保持することで、データの変更を追跡可能
   - 将来的な分析や監査に役立つ可能性がある

2. **パフォーマンス**
   - 適切なインデックスで効率的な検索が可能
   - グループ化による最新データの取得が効率的

3. **柔軟性**
   - 必要に応じて訂正前後のデータを取得可能
   - データの集計や分析時に選択肢が広がる

### 実装の優先順位

1. マイグレーションファイルの作成と実行
2. スキーマの実装
3. データ取得モジュールの実装
   - 認証処理
   - APIリクエスト
   - レスポンスのパース
   - データの保存
4. テストの実装
   - 正常系テスト
   - エラー系テスト
   - データマッピングテスト

#### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.TradesSpec
alias MoomooMarkets.Repo

# 特定の市場区分の投資部門別売買状況を取得（例：TSEPrime）
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
TradesSpec.fetch_trades_spec("TSEPrime", from_date, to_date)

# 保存されたデータの確認
Repo.all(TradesSpec)
```

## 信用取引週末残高（Weekly Margin Interest）

### 概要
J-Quants APIから提供される信用取引週末残高データを管理します。このデータは週末時点での各銘柄の信用取引残高（株数）を提供します。

### データソース
- エンドポイント: `/markets/weekly_margin_interest`
- 提供元: J-Quants API
- 更新頻度: 週次（通常は金曜日基準）
- 参照: [J-Quants API 信用取引週末残高](https://jpx.gitbook.io/j-quants-ja/api-reference/weekly_margin_interest)

### スキーマ定義

#### weekly_margin_interests テーブル

| フィールド名 | 型 | NULL | 説明 |
|------------|-----|------|------|
| code | string | false | 銘柄コード |
| date | date | false | 申込日付（通常は金曜日） |
| issue_type | string | false | 銘柄区分（1: 信用銘柄, 2: 貸借銘柄, 3: その他） |
| short_margin_trade_volume | float | false | 売合計信用取引週末残高 |
| long_margin_trade_volume | float | false | 買合計信用取引週末残高 |
| short_negotiable_margin_trade_volume | float | false | 売一般信用取引週末残高 |
| long_negotiable_margin_trade_volume | float | false | 買一般信用取引週末残高 |
| short_standardized_margin_trade_volume | float | false | 売制度信用取引週末残高 |
| long_standardized_margin_trade_volume | float | false | 買制度信用取引週末残高 |
| inserted_at | utc_datetime | false | レコード作成日時 |
| updated_at | utc_datetime | false | レコード更新日時 |

#### インデックス

| 名前 | フィールド | 種類 | 説明 |
|------|------------|------|------|
| weekly_margin_interests_code_date_index | [code, date] | unique | 銘柄・日付の一意性保証 |
| weekly_margin_interests_date_index | [date] | index | 日付による検索効率化 |
| weekly_margin_interests_code_index | [code] | index | 銘柄による検索効率化 |
| weekly_margin_interests_issue_type_index | [issue_type] | index | 銘柄区分による検索効率化 |

### 制約事項

1. データの特性
   - コーポレートアクション発生時も株数の遡及調整は行われない
   - 年末年始など営業日が2日以下の週はデータ非提供
   - 東証上場銘柄以外（地方取引所単独上場銘柄）は対象外

2. API制約
   - 銘柄コード（code）または日付（date）のいずれかが必須
   - レスポンスサイズが大きい場合はページネーション必要

### 主要機能

1. データ取得
   ```elixir
   # 特定銘柄の全期間データ取得
   WeeklyMarginInterest.fetch_by_code(code)
   
   # 特定日付の全銘柄データ取得
   WeeklyMarginInterest.fetch_by_date(date)
   
   # 特定銘柄の期間指定データ取得
   WeeklyMarginInterest.fetch_by_code_and_period(code, from, to)
   ```

2. データ保存
   ```elixir
   # 単一データの保存
   WeeklyMarginInterest.save_weekly_margin_interest(params)
   
   # バッチ処理による一括取得・保存
   WeeklyMarginInterest.fetch_all_weekly_margin_interests(date)
   ```

### エラーハンドリング

1. APIエラー
   - 400: パラメータ不正
   - 401: 認証エラー
   - 403: アクセス権限エラー
   - 413: レスポンスサイズ超過
   - 500: サーバーエラー

2. 対応方針
   - トークン期限切れ時の自動リフレッシュ
   - 大量データ取得時の分割処理
   - 一時的なエラー発生時のリトライ処理

### 実装計画

1. フェーズ1: 基本実装
   - スキーマとマイグレーションの作成
   - 基本的なデータ取得機能の実装
   - 単体テストの作成

2. フェーズ2: 拡張機能
   - バッチ処理の実装
   - エラーハンドリングの強化
   - 統合テストの追加

3. フェーズ3: 最適化
   - パフォーマンスチューニング
   - モニタリング機能の追加
   - ドキュメントの更新

#### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest
alias MoomooMarkets.Repo

# 特定の銘柄の信用取引週末残高を取得（例：86970）
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
WeeklyMarginInterest.fetch_by_code("86970", from_date, to_date)

# 特定の日付の全銘柄の信用取引週末残高を取得
date = ~D[2024-03-25]
WeeklyMarginInterest.fetch_by_date(date)

# 保存されたデータの確認
Repo.all(WeeklyMarginInterest) 
```

## 週間信用取引残高データ (Weekly Margin Interest)

### 概要
週間信用取引残高データは、J-Quants APIから取得し、データベースに保存します。
銘柄ごとの週間信用取引残高（空売り残高、買い残高）を記録します。

### スキーマ定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    code: String.t(),
    date: Date.t(),
    issue_type: String.t(),
    short_margin_volume: float(),
    long_margin_volume: float(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "weekly_margin_interests" do
    field :code, :string
    field :date, :date
    field :issue_type, :string
    field :short_margin_volume, :float
    field :long_margin_volume, :float

    timestamps()
  end

  @doc false
  def changeset(weekly_margin_interest, attrs) do
    weekly_margin_interest
    |> cast(attrs, [:code, :date, :issue_type, :short_margin_volume, :long_margin_volume])
    |> validate_required([:code, :date, :issue_type, :short_margin_volume, :long_margin_volume])
    |> unique_constraint([:code, :date, :issue_type])
  end
end
```

### マイグレーション
```elixir
defmodule MoomooMarkets.Repo.Migrations.CreateWeeklyMarginInterests do
  use Ecto.Migration

  def change do
    create table(:weekly_margin_interests) do
      add :code, :string, null: false, comment: "銘柄コード"
      add :date, :date, null: false, comment: "日付"
      add :issue_type, :string, null: false, comment: "発行種別"
      add :short_margin_volume, :float, null: false, comment: "空売り残高"
      add :long_margin_volume, :float, null: false, comment: "買い残高"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:weekly_margin_interests, [:code, :date, :issue_type])

    # 個別のインデックス
    create index(:weekly_margin_interests, [:code])
    create index(:weekly_margin_interests, [:date])
    create index(:weekly_margin_interests, [:issue_type])
  end
end
```

### 考慮事項

1. **データの重複**
   - 銘柄コード、日付、発行種別の組み合わせでユニーク制約を設定
   - 既存データの更新処理の実装

2. **エラーハンドリング**
   - APIエラーの適切な処理
   - データの欠損や不正な値の処理

3. **パフォーマンス**
   - バッチ処理の実装
   - インデックスの適切な設定
   - 大量データ取得時のページネーション対応

### 実装の優先順位

1. マイグレーションファイルの作成と実行
2. スキーマの実装
3. データ取得モジュールの実装
   - 認証処理
   - APIリクエスト
   - レスポンスのパース
   - データの保存
4. テストの実装
   - 正常系テスト
   - エラー系テスト
   - データマッピングテスト

### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest
alias MoomooMarkets.Repo

# 特定の銘柄の週間信用取引残高データを取得（例：86970）
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
WeeklyMarginInterest.fetch_weekly_margin_interest("86970", from_date, to_date)

# 保存されたデータの確認
Repo.all(WeeklyMarginInterest)
```

## 業種別空売り比率データ (Short Selling)

### 概要
業種別空売り比率データは、J-Quants APIから取得し、データベースに保存します。
日々の業種（セクター）別の空売り比率に関する売買代金を記録します。

### スキーマ定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.ShortSelling do
  use Ecto.Schema
  import Ecto.Changeset

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
end
```

### マイグレーション
```elixir
defmodule MoomooMarkets.Repo.Migrations.CreateShortSellings do
  use Ecto.Migration

  def change do
    create table(:short_sellings) do
      add :date, :date, null: false, comment: "日付"
      add :sector33_code, :string, null: false, comment: "33業種コード"
      add :selling_excluding_short_selling_turnover_value, :float, null: false, comment: "実注文の売買代金"
      add :short_selling_with_restrictions_turnover_value, :float, null: false, comment: "価格規制有りの空売り売買代金"
      add :short_selling_without_restrictions_turnover_value, :float, null: false, comment: "価格規制無しの空売り売買代金"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:short_sellings, [:date, :sector33_code])

    # 個別のインデックス
    create index(:short_sellings, [:date])
    create index(:short_sellings, [:sector33_code])
  end
end
```

### 考慮事項

1. **データの重複**
   - 日付と33業種コードの組み合わせでユニーク制約を設定
   - 既存データの更新処理の実装

2. **エラーハンドリング**
   - APIエラーの適切な処理
   - データの欠損や不正な値の処理
   - 取引高が存在しない日の処理

3. **パフォーマンス**
   - バッチ処理の実装
   - インデックスの適切な設定
   - 大量データ取得時のページネーション対応

### 実装の優先順位

1. マイグレーションファイルの作成と実行
2. スキーマの実装
3. データ取得モジュールの実装
   - 認証処理
   - APIリクエスト
   - レスポンスのパース
   - データの保存
4. テストの実装
   - 正常系テスト
   - エラー系テスト
   - データマッピングテスト

### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.ShortSelling
alias MoomooMarkets.Repo

# 特定の業種の空売り比率データを取得（例：0050）
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
ShortSelling.fetch_short_selling("0050", from_date, to_date)

# 保存されたデータの確認
Repo.all(ShortSelling)

# 特定の業種に絞る
Repo.all(from s in ShortSelling, where: s.sector33_code == "0050", order_by: [desc: s.date])
```

## 売買内訳データ (Breakdown)

### 概要
売買内訳データは、J-Quants APIから取得し、データベースに保存します。
東証上場銘柄の東証市場における銘柄別の日次売買代金・売買高（立会内取引に限る）について、信用取引や空売りの利用に関する発注時のフラグ情報を用いて細分化したデータを記録します。

### スキーマ定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.Breakdown do
  use Ecto.Schema
  import Ecto.Changeset

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
end
```

### マイグレーション
```elixir
defmodule MoomooMarkets.Repo.Migrations.CreateBreakdowns do
  use Ecto.Migration

  def change do
    create table(:breakdowns) do
      add :date, :date, null: false, comment: "売買日"
      add :code, :string, null: false, comment: "銘柄コード"
      add :long_sell_value, :float, null: false, comment: "実売りの約定代金"
      add :short_sell_without_margin_value, :float, null: false, comment: "空売り(信用新規売りを除く)の約定代金"
      add :margin_sell_new_value, :float, null: false, comment: "信用新規売りの約定代金"
      add :margin_sell_close_value, :float, null: false, comment: "信用返済売りの約定代金"
      add :long_buy_value, :float, null: false, comment: "現物買いの約定代金"
      add :margin_buy_new_value, :float, null: false, comment: "信用新規買いの約定代金"
      add :margin_buy_close_value, :float, null: false, comment: "信用返済買いの約定代金"
      add :long_sell_volume, :float, null: false, comment: "実売りの約定株数"
      add :short_sell_without_margin_volume, :float, null: false, comment: "空売り(信用新規売りを除く)の約定株数"
      add :margin_sell_new_volume, :float, null: false, comment: "信用新規売りの約定株数"
      add :margin_sell_close_volume, :float, null: false, comment: "信用返済売りの約定株数"
      add :long_buy_volume, :float, null: false, comment: "現物買いの約定株数"
      add :margin_buy_new_volume, :float, null: false, comment: "信用新規買いの約定株数"
      add :margin_buy_close_volume, :float, null: false, comment: "信用返済買いの約定株数"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:breakdowns, [:date, :code])

    # 個別のインデックス
    create index(:breakdowns, [:date])
    create index(:breakdowns, [:code])
  end
end
```

### 考慮事項

1. **データの重複**
   - 日付と銘柄コードの組み合わせでユニーク制約を設定
   - 既存データの更新処理の実装

2. **エラーハンドリング**
   - APIエラーの適切な処理
   - データの欠損や不正な値の処理
   - 取引高が存在しない日の処理
   - コーポレートアクション発生時の処理

3. **パフォーマンス**
   - バッチ処理の実装
   - インデックスの適切な設定
   - 大量データ取得時のページネーション対応

### 実装の優先順位

1. マイグレーションファイルの作成と実行
2. スキーマの実装
3. データ取得モジュールの実装
   - 認証処理
   - APIリクエスト
   - レスポンスのパース
   - データの保存
4. テストの実装
   - 正常系テスト
   - エラー系テスト
   - データマッピングテスト

### iEXでのデータ取得方法
```elixir
# 必要なモジュールのエイリアスを設定
alias MoomooMarkets.DataSources.JQuants.Breakdown
alias MoomooMarkets.Repo

# 特定の銘柄の売買内訳データを取得
from_date = ~D[2024-03-20]
to_date = ~D[2024-03-25]
Breakdown.fetch_breakdown("13010", from_date, to_date)

# 保存されたデータの確認
Repo.all(Breakdown)

# 特定の銘柄に絞る
Repo.all(from b in Breakdown, where: b.code == "13010", order_by: [desc: b.date])