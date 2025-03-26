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

6. J-Quants API認証の実装
   - トークン管理システムの実装
   - 自動トークンリフレッシュの実装
   - テストカバレッジの追加（Bypass使用）
   - マイクロ秒の問題解決（DateTime.truncate使用）

## 2024-03-25

### J-Quants API上場情報取得機能の実装
- 上場情報取得APIの実装
  - `Stock`スキーマの作成
  - データベースマイグレーションの実装
  - APIレスポンスのマッピング処理の実装
  - バッチ処理による効率的なデータ保存
  - タイムスタンプ処理の実装（マイクロ秒対応）

### J-Quants API投資部門別売買状況の実装
- 投資部門別売買状況APIの実装
  - `TradesSpec`スキーマの作成
  - データベースマイグレーションの実装
  - APIレスポンスのマッピング処理の実装
  - 市場区分の定義と検証機能の実装

### 実装詳細
1. データベース設計
   - `stocks`テーブルの作成
   - 必要なインデックスの設定
   - 制約の設定（NOT NULL, UNIQUE）
   - `trades_specs`テーブルの作成
   - 複合ユニーク制約の設定（published_date, start_date, end_date, section）
   - 各フィールドにNOT NULL制約とコメントを設定
   - インデックスの設定（published_date, start_date, end_date, section）

2. API実装
   - 上場情報取得エンドポイントの実装
   - レスポンスデータのマッピング
   - エラーハンドリング
   - 投資部門別売買状況取得エンドポイントの実装
   - レスポンスデータのマッピング
   - エラーハンドリング
   - 市場区分の検証機能

3. データ保存処理
   - バッチ処理による効率的な保存
   - 重複データの更新処理
   - タイムスタンプの適切な処理

### 動作確認
- 上場情報の取得と保存が正常に動作することを確認
- データの整合性を確認
- パフォーマンスを確認
- 市場区分の取得と検証が正常に動作することを確認
- データの取得と保存が正常に動作することを確認

### 次のステップ
1. データ更新頻度の制御
2. エラーハンドリングの強化
3. データの検証機能
4. バッチ処理の最適化

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

4. テストの実装
   - スキーマモジュールのテスト
   - データ取得・保存機能のテスト
   - エラーケースのテスト

5. データ取得の自動化
   - GenServerによる定期実行の実装
   - エラーハンドリングの強化
   - データの検証機能の追加

## 2024-03-24

### J-Quants API認証の実装
- トークン管理システムの実装
- 自動トークンリフレッシュの実装
- Bypassを使用したテストカバレッジの追加
- マイクロ秒の問題解決（DateTime.truncate使用）

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

#### J-Quants API認証テスト
- テストの構造
  ```elixir
  defmodule MoomooMarkets.DataSources.JQuants.AuthTest do
    use MoomooMarkets.DataCase

    describe "ensure_valid_id_token/1" do
      test "IDトークンが有効な場合、そのトークンを返す"
      test "IDトークンが無効でリフレッシュトークンが有効な場合、新しいIDトークンを取得する"
      test "両方のトークンが無効な場合、新しいトークンを取得する"
      test "認証情報が見つからない場合、エラーを返す"
      test "APIエラーの場合、エラーを返す"
      test "APIサーバーがダウンしている場合、エラーを返す"
    end
  end
  ```

- Bypassを使用したモック
  ```elixir
  # テスト環境設定
  config :moomoo_markets, :jquants_api_base_url, 
    "http://localhost:#{System.get_env("BYPASS_PORT", "4040")}"

  # テストセットアップ
  setup do
    bypass = Bypass.open(port: 4040)
    # ... テストデータのセットアップ
  end

  # APIレスポンスのモック
  Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
  end)
  ```

### 次のステップ
1. データソースクライアントの実装
   - J-Quants APIクライアントの実装
   - レート制限の実装
   - エラーハンドリングの実装

2. データ取得バッチの実装
   - 日次株価データの取得
   - 企業情報の取得
   - エラーハンドリング

3. ジョブキューの実装
   - GenServerを使用したキューの管理
   - 非同期処理の実装
   - エラーハンドリング 