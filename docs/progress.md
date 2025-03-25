# 実装進捗

## 認証システムの実装

### 完了項目
1. ユーザー認証システムの生成
   - `mix phx.gen.auth Accounts User users`コマンドで生成
   - 必要なテーブルとマイグレーションが作成

2. シードユーザーの設定
   - 環境変数による設定（`.env`ファイル）
   - デフォルト値の設定
   - ユーザー作成時の確認済み状態の設定

3. データソースの基本構造
   - `DataSource`スキーマの作成
   - `provider_type`のユニーク制約設定
   - J-Quants APIの基本設定

4. データソース認証情報の管理
   - `DataSourceCredential`スキーマの作成
   - ユーザーとデータソースの関連付け
   - 認証情報の暗号化保存（Phoenix.Token使用）
   - トークン管理（リフレッシュトークン、IDトークン）

5. データソースクライアントの設計
   - 共通インターフェースの定義
   - ディレクトリ構造の設計
   - エラーハンドリングの設計
   - 型定義の設計

### 実装詳細

#### ユーザー認証
- シードユーザーの設定
  ```elixir
  # .env
  SEED_USER_EMAIL=admin@example.com
  SEED_USER_PASSWORD=iS6gLseT$w*AA666
  ```
- ユーザー作成時の確認済み設定
  ```elixir
  user
  |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second))
  |> Repo.update!()
  ```

#### データソース
- スキーマ定義
  ```elixir
  schema "data_sources" do
    field :name, :string
    field :description, :text
    field :provider_type, :string
    field :is_enabled, :boolean, default: false
    field :base_url, :string
    field :api_version, :string
    field :rate_limit_per_minute, :integer
    field :rate_limit_per_hour, :integer
    field :rate_limit_per_day, :integer

    timestamps(type: :utc_datetime)
  end
  ```
- J-Quants APIの設定
  ```elixir
  %DataSource{
    name: "J-Quants API",
    description: "JPX Market Innovation & Research, Inc.が提供する日本市場の金融データAPI",
    provider_type: "jquants",
    is_enabled: true,
    base_url: "https://api.jquants.com/v1",
    api_version: "v1",
    rate_limit_per_minute: 30,
    rate_limit_per_hour: 1000,
    rate_limit_per_day: 10000
  }
  ```

#### データソース認証情報
- スキーマ定義
  ```elixir
  schema "data_source_credentials" do
    field :encrypted_credentials, :binary
    field :refresh_token, :string
    field :refresh_token_expired_at, :utc_datetime
    field :id_token, :string
    field :id_token_expired_at, :utc_datetime

    belongs_to :user, MoomooMarkets.Accounts.User
    belongs_to :data_source, MoomooMarkets.DataSources.DataSource

    timestamps(type: :utc_datetime)
  end
  ```
- 認証情報の暗号化
  ```elixir
  # 認証情報の暗号化と保存
  credentials = %{
    mailaddress: System.get_env("SEED_JQUANTS_EMAIL"),
    password: System.get_env("SEED_JQUANTS_PASSWORD")
  }

  encrypted_credentials = credentials
    |> Jason.encode!()
    |> Encryption.encrypt()
  ```

#### データソースクライアント
- 共通インターフェース
  ```elixir
  defmodule MoomooMarkets.DataSources.Client do
    @callback fetch_data(any(), keyword()) :: {:ok, any()} | {:error, any()}
    @callback refresh_token(any()) :: {:ok, any()} | {:error, any()}
  end
  ```
- ディレクトリ構造
  ```
  lib/
    moomoo_markets/
      data_sources/
        client.ex           # 共通のクライアントビヘイビア
        types.ex           # 共通の型定義
        error.ex           # 共通のエラー定義
        jquants/           # J-Quants固有の実装
        yfinance/          # yfinance固有の実装
  ```

### 次のステップ
1. データソースクライアントの実装
   - J-Quants APIクライアント
   - 認証情報の自動更新
   - レート制限の実装

2. データ取得バッチの実装
   - 日次株価データ取得
   - 企業情報取得
   - エラーハンドリング

3. ジョブキューシステムの実装
   - GenServerによるキュー管理
   - 非同期処理の実装
   - ジョブの状態管理 