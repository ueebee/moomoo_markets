# データソース管理設計

## 概要
株式データ分析プラットフォームにおける複数のデータソース（J-Quants API, yfinance等）の管理と、それらに必要なクレデンシャルの管理を実装します。

## データベース設計

### users テーブル
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email STRING NOT NULL UNIQUE,
    hashed_password STRING NOT NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    role VARCHAR(50) NOT NULL DEFAULT 'user', -- 'admin', 'user' など
    is_active BOOLEAN NOT NULL DEFAULT true,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX users_email_idx ON users(email);
```

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
    -- 認証情報（暗号化して保存）
    encrypted_mailaddress TEXT,
    encrypted_password TEXT,
    encrypted_refresh_token TEXT,
    encrypted_id_token TEXT,
    refresh_token_expires_at TIMESTAMP WITH TIME ZONE,
    id_token_expires_at TIMESTAMP WITH TIME ZONE,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(provider_type)
);

CREATE INDEX data_sources_provider_type_idx ON data_sources(provider_type);
```

## アプリケーション構成

### 1. コンテキスト
- `lib/moo_markets/accounts.ex`
  - ユーザー管理のコンテキスト
  - ユーザーのCRUD操作
  - 認証・認可の管理

- `lib/moo_markets/data_sources.ex`
  - データソース管理のコンテキスト
  - データソースのCRUD操作
  - クレデンシャルの管理
  - 機能の管理

### 2. スキーマ
- `lib/moo_markets/accounts/user.ex`
  - ユーザースキーマ定義
  - パスワードハッシュ化
  - ロール管理

- `lib/moo_markets/data_sources/data_source.ex`
  - データソースのスキーマ定義
  - バリデーションルール
  - レート制限の管理
  - 認証情報の暗号化/復号化

### 3. 暗号化
- `lib/moo_markets/encryption.ex`
  - AES-256-GCMを使用した可逆的暗号化
  - 暗号化キーのローテーション機能
  - 暗号化バージョン管理

### 4. クライアント
- `lib/moo_markets/data_sources/clients/base_client.ex`
  - データソースクライアントの基本インターフェース
  - 共通のエラーハンドリング
  - レート制限の実装

- `lib/moo_markets/data_sources/clients/jquants_client.ex`
  - J-Quants APIクライアントの実装
  - 認証処理
  - エンドポイント実装

### 5. コントローラー
- `lib/moo_markets_web/controllers/user_controller.ex`
  - ユーザー管理のRESTful API
  - ユーザー認証のAPI

- `lib/moo_markets_web/controllers/data_source_controller.ex`
  - データソース管理のRESTful API
  - クレデンシャル管理のAPI

### 6. ビュー
- `lib/moo_markets_web/views/user_view.ex`
  - ユーザー関連のJSONレスポンス定義

- `lib/moo_markets_web/views/data_source_view.ex`
  - データソース関連のJSONレスポンス定義

### 7. テンプレート
- `lib/moo_markets_web/templates/user/`
  - ユーザー管理画面
  - ログイン画面

- `lib/moo_markets_web/templates/data_source/`
  - データソース管理画面

## 実装の考慮点

### 1. セキュリティ
- クレデンシャルの暗号化保存（AES-256-GCM）
  - 暗号化キーのローテーション
  - 暗号化バージョンの管理
  - 復号化可能な方式の採用
- アクセス制御（Guardian）
- 監査ログ
- セッション管理

### 2. レート制限
- プロバイダーごとの制限
- 機能ごとの制限
- バックオフ戦略
- 分散環境での同期（Phoenix.PubSub）

### 3. エラーハンドリング
- APIエラーの適切な処理
- リトライ戦略
- フォールバックメカニズム
- エラー通知（Phoenix.PubSub）

### 4. パフォーマンス
- キャッシュ戦略（Phoenix.PubSub）
- コネクションプール
- タイムアウト設定
- バッチ処理

## 実装優先順位

1. ユーザー管理システムの実装
2. 暗号化モジュールの実装
3. データベース設計とマイグレーション
4. 基本スキーマの実装
5. コンテキストの実装
6. コントローラーとビューの実装
7. テンプレートの実装
8. クライアントインターフェースの実装
9. J-Quantsクライアントの実装
10. レート制限の実装
11. エラーハンドリングの実装
12. パフォーマンス最適化

## テスト計画

1. ユニットテスト
   - ユーザー管理
   - 暗号化/復号化
   - スキーマ
   - クライアント
   - レート制限
   - エラーハンドリング

2. 統合テスト
   - ユーザー認証フロー
   - データソース管理
   - クレデンシャル管理
   - レート制限
   - エラー処理

3. E2Eテスト
   - ユーザー登録/ログインフロー
   - データ取得フロー
   - 認証フロー
   - レート制限
   - エラー処理

## 今後の課題

1. セキュリティ強化
   - 暗号化キーのローテーション自動化
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