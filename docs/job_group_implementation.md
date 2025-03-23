# ジョブグループ機能の実装状況

## 概要
スケジューラーの機能拡張として、複数のジョブをグループ化して管理する機能を実装します。
この機能により、株価四本値データの取得など、複数の銘柄に対して並列にジョブを実行する際の管理が容易になります。

また、複数のデータソース（J-Quants, Yahoo Finance等）からのデータ取得を統一的に管理するため、
データソースの概念を導入します。

## 実装状況

### ✅ 完了
1. データベース設計
   - `data_sources` テーブルの設計
   - `job_groups` テーブルの設計
   - `jobs` テーブルへの `group_id` 追加
   - 必要なインデックスの設計

2. スキーマ定義
   - `MooMarkets.Scheduler.DataSource` スキーマの設計
   - `MooMarkets.Scheduler.JobGroup` スキーマの設計
   - 基本的なバリデーションの設計

### 🚧 進行中
1. データベース実装
   - マイグレーションファイルの作成
   - テーブルとインデックスの作成

2. スキーマ実装
   - `DataSource` スキーマの実装
   - `JobGroup` スキーマの実装
   - 関連付けの実装

### 📝 未着手
1. コンテキストモジュールの作成
   - データソースのCRUD操作
   - ジョブグループのCRUD操作
   - グループ状態の管理
   - 進捗状況の管理

2. LiveView実装
   - データソース一覧画面
   - データソース詳細画面
   - ジョブグループ一覧画面
   - グループ詳細画面
   - グループ作成/編集フォーム

3. ジョブ実行ロジックの拡張
   - グループジョブの実装
   - 子ジョブの生成と管理
   - グループ全体の進捗管理

4. テスト
   - ユニットテスト
   - 統合テスト
   - E2Eテスト

## 次のステップ
1. データベース実装
   - マイグレーションファイルの作成
   - テーブルとインデックスの作成

2. スキーマ実装
   - `DataSource` スキーマの実装
   - `JobGroup` スキーマの実装
   - 関連付けの実装

## 技術的な詳細

### データベース構造
```sql
-- data_sources テーブル
CREATE TABLE data_sources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,           -- 表示用の名前（例：J-Quants, Yahoo Finance）
    code VARCHAR(50) NOT NULL,            -- システム内での識別子（例：jquants, yfinance）
    description TEXT,                     -- 説明
    is_active BOOLEAN NOT NULL DEFAULT true,
    config JSONB,                         -- API設定（認証情報など）
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(code)
);

-- job_groups テーブル
CREATE TABLE job_groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    data_source_id BIGINT REFERENCES data_sources(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- jobs テーブルの拡張
ALTER TABLE jobs ADD COLUMN group_id BIGINT REFERENCES job_groups(id);

-- インデックス
CREATE INDEX data_sources_code_index ON data_sources(code);
CREATE INDEX job_groups_status_index ON job_groups(status);
CREATE INDEX job_groups_data_source_id_index ON job_groups(data_source_id);
CREATE INDEX jobs_group_id_index ON jobs(group_id);
```

### スキーマ定義
```elixir
defmodule MooMarkets.Scheduler.DataSource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_sources" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :config, :map

    has_many :job_groups, MooMarkets.Scheduler.JobGroup

    timestamps()
  end

  @doc false
  def changeset(data_source, attrs) do
    data_source
    |> cast(attrs, [:name, :code, :description, :is_active, :config])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end
end

defmodule MooMarkets.Scheduler.JobGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "job_groups" do
    field :name, :string
    field :status, :string
    belongs_to :data_source, MooMarkets.Scheduler.DataSource
    has_many :jobs, MooMarkets.Scheduler.Job

    timestamps()
  end

  @doc false
  def changeset(job_group, attrs) do
    job_group
    |> cast(attrs, [:name, :status, :data_source_id])
    |> validate_required([:name, :status, :data_source_id])
  end
end
```

## 実装の考慮点
1. データソース管理
   - API認証情報の安全な管理
   - データソースごとの設定管理
   - 有効/無効の制御
   - アクセス制御

2. グループ状態の管理
   - 実行中
   - 完了
   - エラー
   - 一時停止

3. 進捗状況の管理
   - グループ全体の進捗
   - 個別ジョブの進捗
   - エラー発生時の処理

4. パフォーマンス
   - 並列実行の制御
   - リソース使用量の管理
   - データベース負荷の考慮

5. エラーハンドリング
   - 個別ジョブのエラー処理
   - グループ全体のエラー処理
   - リトライ戦略
   - データソース固有のエラー処理

6. UI/UX
   - データソース一覧表示
   - データソース詳細表示
   - ジョブグループ一覧表示
   - グループ詳細表示
   - 設定管理インターフェース 