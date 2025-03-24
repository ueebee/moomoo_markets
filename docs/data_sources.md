# データソース管理設計

## 概要
株式データ分析プラットフォームにおける複数のデータソース（J-Quants API, yfinance等）の管理と、それらに必要なクレデンシャルの管理を実装します。

## アプリケーション構成

### 1. コンテキスト
- `lib/moo_markets/data_sources.ex`
  - データソース管理のコンテキスト
  - データソースのCRUD操作
  - クレデンシャルの管理
  - 機能の管理

### 2. スキーマ
- `lib/moo_markets/data_sources/schemas/data_source.ex`
  - データソースのスキーマ定義
  - バリデーションルール
  - レート制限の管理

- `lib/moo_markets/data_sources/schemas/data_source_credential.ex`
  - クレデンシャルのスキーマ定義
  - 暗号化/復号化機能
  - 有効期限管理

- `lib/moo_markets/data_sources/schemas/data_source_capability.ex`
  - データソースの機能スキーマ定義
  - レート制限の管理

### 3. クライアント
- `lib/moo_markets/data_sources/clients/base_client.ex`
  - データソースクライアントの基本インターフェース
  - 共通のエラーハンドリング
  - レート制限の実装

- `lib/moo_markets/data_sources/clients/jquants_client.ex`
  - J-Quants APIクライアントの実装
  - 認証処理
  - エンドポイント実装

- `lib/moo_markets/data_sources/clients/yfinance_client.ex`
  - yfinanceクライアントの実装
  - 認証処理
  - エンドポイント実装

### 4. レート制限管理
- `lib/moo_markets/data_sources/rate_limiter.ex`
  - レート制限の実装
  - トークンバケットアルゴリズム
  - 分散環境での同期

### 5. コントローラー
- `lib/moo_markets_web/controllers/data_source_controller.ex`
  - データソース管理のRESTful API
  - クレデンシャル管理のAPI
  - 機能管理のAPI

### 6. ビュー
- `lib/moo_markets_web/views/data_source_view.ex`
  - JSONレスポンスの定義
  - エラーレスポンスの定義

### 7. テンプレート
- `lib/moo_markets_web/templates/data_source/`
  - データソース管理画面
  - クレデンシャル管理画面
  - 機能管理画面

### 8. ルーティング
```elixir
# lib/moo_markets_web/router.ex
scope "/api", MooMarketsWeb do
  pipe_through :api

  resources "/data_sources", DataSourceController, only: [:index, :show, :create, :update, :delete] do
    resources "/credentials", DataSourceCredentialController, only: [:index, :show, :create, :update, :delete]
    resources "/capabilities", DataSourceCapabilityController, only: [:index, :show, :create, :update, :delete]
  end
end

scope "/", MooMarketsWeb do
  pipe_through :browser

  get "/data_sources", DataSourceController, :index
  get "/data_sources/new", DataSourceController, :new
  get "/data_sources/:id/edit", DataSourceController, :edit
  resources "/data_sources", DataSourceController
end
```

## データベース設計

### data_sources テーブル
```sql
CREATE TABLE data_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    provider_type VARCHAR(50) NOT NULL, -- 'jquants', 'yfinance' 等
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    base_url TEXT,
    api_version VARCHAR(50),
    rate_limit_per_minute INTEGER,
    rate_limit_per_hour INTEGER,
    rate_limit_per_day INTEGER,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(provider_type)
);

CREATE INDEX data_sources_provider_type_idx ON data_sources(provider_type);
```

### data_source_credentials テーブル
```sql
CREATE TABLE data_source_credentials (
    id SERIAL PRIMARY KEY,
    data_source_id INTEGER NOT NULL REFERENCES data_sources(id),
    credential_type VARCHAR(50) NOT NULL, -- 'api_key', 'username', 'password', 'token' 等
    credential_value TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(data_source_id, credential_type)
);

CREATE INDEX data_source_credentials_data_source_id_idx ON data_source_credentials(data_source_id);
```

### data_source_capabilities テーブル
```sql
CREATE TABLE data_source_capabilities (
    id SERIAL PRIMARY KEY,
    data_source_id INTEGER NOT NULL REFERENCES data_sources(id),
    capability_type VARCHAR(50) NOT NULL, -- 'daily_quotes', 'company_info', 'trading_calendar' 等
    is_supported BOOLEAN NOT NULL DEFAULT true,
    rate_limit_per_minute INTEGER,
    rate_limit_per_hour INTEGER,
    rate_limit_per_day INTEGER,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(data_source_id, capability_type)
);

CREATE INDEX data_source_capabilities_data_source_id_idx ON data_source_capabilities(data_source_id);
```

## 実装の考慮点

### 1. セキュリティ
- クレデンシャルの暗号化保存（Phoenix.PubSubを使用した安全な通信）
- アクセス制御（Guardianを使用した認証/認可）
- 監査ログ
- セッション管理

### 2. レート制限
- プロバイダーごとの制限
- 機能ごとの制限
- バックオフ戦略
- 分散環境での同期（Phoenix.PubSubを使用）

### 3. エラーハンドリング
- APIエラーの適切な処理
- リトライ戦略
- フォールバックメカニズム
- エラー通知（Phoenix.PubSubを使用）

### 4. パフォーマンス
- キャッシュ戦略（Phoenix.PubSubを使用）
- コネクションプール
- タイムアウト設定
- バッチ処理

## 実装優先順位

1. データベース設計とマイグレーション
2. 基本スキーマの実装
3. コンテキストの実装
4. コントローラーとビューの実装
5. テンプレートの実装
6. クライアントインターフェースの実装
7. J-Quantsクライアントの実装
8. yfinanceクライアントの実装
9. レート制限の実装
10. エラーハンドリングの実装
11. セキュリティ機能の実装
12. パフォーマンス最適化

## テスト計画

1. ユニットテスト
   - スキーマ
   - クライアント
   - レート制限
   - エラーハンドリング

2. 統合テスト
   - データソース管理
   - クレデンシャル管理
   - レート制限
   - エラー処理

3. E2Eテスト
   - データ取得フロー
   - 認証フロー
   - レート制限
   - エラー処理

## 今後の課題

1. セキュリティ強化
   - クレデンシャルのローテーション
   - アクセス制御の細分化
   - 監査ログの拡充

2. 機能拡張
   - 新規データソースの追加
   - データソースのヘルスチェック
   - 自動フェイルオーバー

3. 運用性の向上
   - モニタリング機能
   - アラート設定
   - バックアップ/リストア
   - 運用ドキュメント 