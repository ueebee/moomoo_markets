# データモデリング

## エンティティ

### User
- アプリケーションの利用者
- 認証情報を持つ
- データソースの認証情報を管理

### DataSource
- データ取得元の定義
- 例：J-Quants, yfinance
- システム側で管理（ユーザーは追加不可）
- 属性：
  - `name`: データソース名
  - `description`: 説明
  - `provider_type`: プロバイダータイプ（例：`jquants`, `yfinance`）
  - `is_enabled`: 有効/無効フラグ
  - `base_url`: APIのベースURL
  - `api_version`: APIバージョン
  - `rate_limit_per_minute`: レート制限（分）
  - `rate_limit_per_hour`: レート制限（時）
  - `rate_limit_per_day`: レート制限（日）

### DataSourceCredential
- ユーザーごとのデータソース認証情報
- 属性：
  - `user_id`: ユーザーID（外部キー）
  - `data_source_id`: データソースID（外部キー）
  - `encrypted_credentials`: 暗号化された認証情報（JSON形式）
    ```json
    {
      "mailaddress": "user@example.com",
      "password": "password123"
    }
    ```
  - `refresh_token`: リフレッシュトークン
  - `refresh_token_expired_at`: リフレッシュトークンの有効期限（1週間）
  - `id_token`: IDトークン
  - `id_token_expired_at`: IDトークンの有効期限（24時間）

### JobGroup
- データ取得ジョブのグループ
- 属性：
  - `user_id`: ユーザーID（外部キー）
  - `data_source_id`: データソースID（外部キー）
  - `endpoint_id`: APIエンドポイントID（コードで定義されたID）
  - `status`: ジョブグループの状態（pending, running, completed, failed）
  - `started_at`: 開始日時
  - `completed_at`: 完了日時
  - `error_message`: エラーメッセージ
  - `total_jobs`: 子ジョブの総数
  - `completed_jobs`: 完了した子ジョブ数
  - `failed_jobs`: 失敗した子ジョブ数

### Job
- 個別のデータ取得ジョブ
- 属性：
  - `job_group_id`: ジョブグループID（外部キー）
  - `symbol`: 銘柄コード（エンドポイントの設定に基づく）
  - `status`: ジョブの状態（pending, running, completed, failed）
  - `started_at`: 開始日時
  - `completed_at`: 完了日時
  - `error_message`: エラーメッセージ
  - `response_data`: 取得したデータ（JSONB）
  - `retry_count`: リトライ回数
  - `last_retry_at`: 最終リトライ日時

## リレーション

```
User
  has_many DataSourceCredential
  has_many JobGroup

DataSource
  has_many DataSourceCredential
  has_many JobGroup

DataSourceCredential
  belongs_to User
  belongs_to DataSource

JobGroup
  belongs_to User
  belongs_to DataSource
  has_many Job

Job
  belongs_to JobGroup
```

## 特徴

1. データソースの分離
   - システム側で管理する基本情報（DataSource）
   - ユーザー側で管理する認証情報（DataSourceCredential）

2. APIエンドポイントのコード管理
   - エンドポイントの定義はコードで管理
   - 型安全性の確保
   - バージョン管理の容易さ
   - 実装の一貫性

3. ジョブ管理
   - グループ化による関連ジョブの管理
   - 進捗状況の追跡
   - エラーハンドリングとリトライ

4. スケーラビリティ
   - 非同期処理による大量データ取得
   - レート制限によるAPI保護
   - ジョブグループによる効率的な管理

## APIエンドポイントの定義例

```elixir
# lib/moomoo_markets/data_sources/endpoints.ex
defmodule MoomooMarkets.DataSources.Endpoints do
  def jquants_endpoints do
    %{
      "daily_quotes" => %{
        name: "日次株価",
        path: "/daily_quotes",
        method: "GET",
        requires_symbol: true,
        rate_limit: %{
          per_minute: 30,
          per_hour: 1000,
          per_day: 10000
        }
      },
      "company_info" => %{
        name: "企業情報",
        path: "/company_info",
        method: "GET",
        requires_symbol: true,
        rate_limit: %{
          per_minute: 30,
          per_hour: 1000,
          per_day: 10000
        }
      }
    }
  end
end
```

## 認証情報の管理

### DataSourceCredentialの主要機能

1. 認証情報の暗号化
   - ユーザーの認証情報（メールアドレス、パスワード）をJSON形式で暗号化
   - AES-256-GCMによる暗号化
   - キーローテーション対応

2. トークン管理
   - リフレッシュトークン（1週間有効）
   - IDトークン（24時間有効）
   - トークンの有効期限管理
   - 自動更新機能

3. セキュリティ対策
   - 認証情報の暗号化保存
   - トークンの有効期限管理
   - ユーザーごとの認証情報分離
   - データソースごとの認証情報分離

4. パフォーマンス最適化
   - インデックスによる高速な検索
   - トークンの有効性チェックの効率化
   - キャッシュ戦略の実装