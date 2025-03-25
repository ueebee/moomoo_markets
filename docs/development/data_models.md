# データモデル設計

## 株価データ (Stock Prices)

### 概要
株価データは、J-Quants APIから取得した株価四本値（始値、高値、安値、終値）と関連する情報を保存します。
現在は基本機能のみを実装し、Premiumプラン機能（前場/後場データ）は将来的な拡張対象としています。

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
    volume: integer(),
    turnover_value: integer(),
    adjustment_factor: float(),
    adjustment_open: float(),
    adjustment_high: float(),
    adjustment_low: float(),
    adjustment_close: float(),
    adjustment_volume: integer(),
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
    field :volume, :integer
    field :turnover_value, :integer
    field :adjustment_factor, :float
    field :adjustment_open, :float
    field :adjustment_high, :float
    field :adjustment_low, :float
    field :adjustment_close, :float
    field :adjustment_volume, :integer

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
      add :volume, :integer, null: false
      add :turnover_value, :integer, null: false
      add :adjustment_factor, :float, null: false
      add :adjustment_open, :float, null: false
      add :adjustment_high, :float, null: false
      add :adjustment_low, :float, null: false
      add :adjustment_close, :float, null: false
      add :adjustment_volume, :integer, null: false

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
  alias MoomooMarkets.DataSources.JQuants.{Auth, Error, Types}
  alias MoomooMarkets.Repo

  @doc """
  指定された銘柄コードの株価四本値データを取得します
  """
  @spec fetch_stock_prices(String.t(), Date.t(), Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_stock_prices(code, from_date, to_date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, code, from_date, to_date),
         {:ok, data} <- parse_response(response) do
      save_stock_prices(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  全銘柄の株価四本値データを取得します
  """
  @spec fetch_all_stock_prices(Date.t()) :: {:ok, [t()]} | {:error, Error.t()}
  def fetch_all_stock_prices(date) do
    with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
         {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
         {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token, date),
         {:ok, data} <- parse_response(response) do
      save_stock_prices(data)
    else
      {:error, reason} -> {:error, reason}
    end
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