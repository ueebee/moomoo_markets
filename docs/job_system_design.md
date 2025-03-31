# ジョブシステム設計

## 概要
GenServerとObanを使用した非同期データ取得システムの設計。データソースとジョブグループの概念を導入し、効率的なデータ取得を実現する。

## コア概念

### 1. DataSource
データソースを抽象化する概念。各データソース（J-Quants, yfinance等）の実装を提供。

```elixir
defmodule MoomooMarkets.DataSource do
  @callback fetch_data(any()) :: {:ok, any()} | {:error, any()}
  @callback validate_credentials() :: boolean()
  @callback get_rate_limit() :: {integer(), :second | :minute | :hour}
end
```

### 2. JobGroup
スキーマ種別ごとの管理を行う概念。複数のジョブをグループ化し、関連するジョブの実行を制御。

```elixir
defmodule MoomooMarkets.Jobs.JobGroup do
  schema "job_groups" do
    field :name, :string
    field :description, :string
    field :schema_module, :string
    field :data_source_id, :integer
    field :schedule, :string
    field :parameters_template, :map
    field :is_enabled, :boolean, default: true

    timestamps()
  end
end
```

### 3. JobGroupManager (GenServer)
ジョブグループ全体を管理するGenServer。ジョブの作成、スケジュール管理、状態管理を行う。

```elixir
defmodule MoomooMarkets.Jobs.JobGroupManager do
  use GenServer

  # Client API
  def create_jobs_for_group(group_id)
  def update_group_schedule(group_id, schedule)
  def enable_group(group_id)
  def disable_group(group_id)

  # Server Callbacks
  def init(_opts)
  def handle_call({:create_jobs_for_group, group_id}, _from, state)
  def handle_call({:update_group_schedule, group_id, schedule}, _from, state)
  def handle_call({:enable_group, group_id}, _from, state)
  def handle_call({:disable_group, group_id}, _from, state)
  def handle_info(:check_job_groups, state)
end
```

### 4. DataFetchWorker (Oban.Worker)
実際のデータ取得を実行するObanワーカー。

```elixir
defmodule MoomooMarkets.Workers.DataFetchWorker do
  use Oban.Worker

  def perform(%Oban.Job{args: %{"job_group_id" => group_id, "parameters" => parameters}})
end
```

## システムアーキテクチャ

### 1. 階層構造
```
JobGroup (スキーマ)
  └── JobGroupManager (GenServer)
       └── Oban.Job (ジョブ)
            └── DataFetchWorker (ワーカー)
```

### 2. データフロー
1. JobGroupManagerが定期的にスケジュールをチェック
2. 実行可能なジョブグループに対してObanジョブを作成
3. DataFetchWorkerが実際のデータ取得を実行

## スケジュール管理

### 1. Cron形式
- 標準的なCron式を使用
- 例: "0 0 * * *" (毎日0時に実行)

### 2. スケジュール検証
- Cron式の構文チェック
- 次の実行時間の計算

## ジョブ管理

### 1. ジョブ作成
- 単一ジョブ: パラメータテンプレートなし
- 複数ジョブ: パラメータテンプレートに基づいて生成
  - 例: 複数の銘柄コードに対してジョブを作成

### 2. 状態管理
- ジョブグループの有効/無効
- ジョブの状態（available/scheduled）

## エラーハンドリング

### 1. ジョブレベル
- Obanの標準的なエラーハンドリング
- ジョブの再試行

### 2. グループレベル
- ジョブグループの一時停止/再開
- エラーログの記録

## 今後の拡張性

### 1. JobGroupDependency (TODO)
- ジョブグループ間の依存関係管理
  - 例：株価データの取得完了後に分析ジョブを実行
  - 複数のデータソースからのデータ取得の順序制御
  - データの前処理と後処理の連携
- 実装優先度：中
- 実装時期：必要に応じて後日実装

### 2. モニタリング
- ジョブ実行状況の監視
- メトリクス収集
- アラート設定

### 3. 運用管理
- ダッシュボードの実装
- バックアップ/リストア機能

   08082804402 下手