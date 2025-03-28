# ジョブシステム設計

## 概要
GenServerを使用した非同期データ取得システムの設計。データソースとジョブグループの概念を導入し、効率的なデータ取得を実現する。

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
スキーマ種別ごとの管理を行う概念。複数のJobをグループ化し、関連するジョブの実行を制御。

```elixir
defmodule MoomooMarkets.Jobs.JobGroup do
  schema "job_groups" do
    field :name, :string
    field :description, :string
    field :data_source, :string
    field :level, :integer, default: 1
    field :schedule, :map
    field :status, :string, default: "idle"
    field :last_run_at, :utc_datetime
    field :next_run_at, :utc_datetime
    field :error_count, :integer, default: 0
    field :max_retries, :integer, default: 3
    field :retry_delay, :integer, default: 300

    # Associations
    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :jobs, MoomooMarkets.Jobs.Job
    has_many :dependencies, MoomooMarkets.Jobs.JobGroupDependency
    has_many :depends_on, MoomooMarkets.Jobs.JobGroupDependency
  end
end
```

### 3. Job
実際のデータ取得タスクを表す概念。単一のAPIコールで完結するものから、複数のAPIコールが必要なものまで対応。

```elixir
defmodule MoomooMarkets.Jobs.Job do
  schema "jobs" do
    field :name, :string
    field :description, :string
    field :parameters, :map
    field :status, :string, default: "idle"
    field :last_run_at, :utc_datetime
    field :next_run_at, :utc_datetime
    field :error_count, :integer, default: 0
    field :max_retries, :integer, default: 3
    field :retry_delay, :integer, default: 300
    field :last_error, :string
    field :result, :map

    belongs_to :job_group, MoomooMarkets.Jobs.JobGroup
  end
end
```

### 4. JobGroupDependency
ジョブグループ間の依存関係を管理する概念。

```elixir
defmodule MoomooMarkets.Jobs.JobGroupDependency do
  schema "job_group_dependencies" do
    belongs_to :job_group, MoomooMarkets.Jobs.JobGroup
    belongs_to :depends_on, MoomooMarkets.Jobs.JobGroup
  end
end
```

## システムアーキテクチャ

### 1. JobManager (GenServer)
ジョブシステム全体を管理するGenServer。

```elixir
defmodule MoomooMarkets.Jobs.JobManager do
  use GenServer

  def init(_) do
    {:ok, %{
      job_groups: %{},
      running_groups: %{},
      data_sources: %{}
    }}
  end

  # ジョブグループの管理
  def start_job_group(job_group)
  def stop_job_group(job_group_id)
  def pause_job_group(job_group_id)
  def resume_job_group(job_group_id)

  # ジョブの管理
  def schedule_job(job_group_id, job)
  def cancel_job(job_id)
  def retry_job(job_id)

  # 状態管理
  def get_job_status(job_id)
  def get_job_group_status(job_group_id)
  def get_system_status()
end
```

### 2. JobExecutor (GenServer)
個々のジョブを実行するGenServer。

```elixir
defmodule MoomooMarkets.Jobs.JobExecutor do
  use GenServer

  def init(job) do
    {:ok, %{
      job: job,
      status: :idle,
      current_attempt: 0,
      last_error: nil
    }}
  end

  def execute()
  def handle_failure(error)
  def handle_success(result)
end
```

### 3. RateLimiter (GenServer)
APIレート制限を管理するGenServer。

```elixir
defmodule MoomooMarkets.RateLimiter do
  use GenServer

  def init(data_source) do
    {:ok, %{
      data_source: data_source,
      tokens: max_tokens,
      last_refill: System.system_time(:second)
    }}
  end

  def acquire_token()
  def release_token()
end
```

## データフロー

1. ジョブグループの登録
   - JobManagerにジョブグループを登録
   - 関連するDataSourceの初期化
   - スケジュールの設定

2. ジョブの実行
   - JobManagerがスケジュールに基づきジョブを実行
   - JobExecutorが実際のデータ取得を実行
   - RateLimiterがAPIコールの制御を行う

3. 結果の処理
   - 成功時：データの保存と次の実行スケジュールの設定
   - 失敗時：リトライロジックの実行またはエラー報告

## エラーハンドリング

1. ジョブレベル
   - 最大リトライ回数の設定
   - バックオフ戦略の実装
   - エラーログの記録

2. グループレベル
   - 依存関係のあるジョブの制御
   - グループ全体の一時停止/再開
   - エラー通知の設定

## スケジュール管理

1. スケジュールタイプ
   - Cron形式: 複雑なスケジュール設定
   - Interval形式: 一定間隔での実行

2. スケジュール検証
   - Cron式の構文チェック
   - タイムゾーンの検証
   - 実行時間の計算

## 監視と管理

1. メトリクス
   - ジョブ実行時間
   - 成功率/失敗率
   - リソース使用量

2. ログ
   - 実行ログ
   - エラーログ
   - パフォーマンスログ

## 今後の拡張性

1. スケーリング
   - 分散実行のサポート
   - 負荷分散の実装
   - クラスタリング対応

2. 機能拡張
   - 新しいデータソースの追加
   - 複雑なスケジュール設定
   - 高度なエラーハンドリング

3. 運用管理
   - ダッシュボードの実装
   - アラート設定
   - バックアップ/リストア機能 

   08082804402 下手