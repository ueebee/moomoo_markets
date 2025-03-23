# 株価四本値データ取得機能

## 概要
J-Quants APIを使用して株価四本値データを取得し、データベースに保存する機能を実装します。
※本実装ではBasicプランの機能のみを対象とし、Premiumプランで利用可能な前場/後場別データは対象外とします。

## データベース設計

### daily_quotes テーブル
```sql
CREATE TABLE daily_quotes (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL,
    code VARCHAR(10) NOT NULL,
    open DECIMAL(10,2),
    high DECIMAL(10,2),
    low DECIMAL(10,2),
    close DECIMAL(10,2),
    volume BIGINT,
    turnover_value BIGINT,
    adjustment_factor DECIMAL(10,4),
    adjustment_open DECIMAL(10,2),
    adjustment_high DECIMAL(10,2),
    adjustment_low DECIMAL(10,2),
    adjustment_close DECIMAL(10,2),
    adjustment_volume BIGINT,
    upper_limit VARCHAR(1),
    lower_limit VARCHAR(1),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(date, code)
);

CREATE INDEX daily_quotes_date_idx ON daily_quotes(date);
CREATE INDEX daily_quotes_code_idx ON daily_quotes(code);
```

### カラム説明
- `date`: 取引日（YYYY-MM-DD形式）
- `code`: 銘柄コード（4桁または5桁）
- `open`: 始値（調整前）
- `high`: 高値（調整前）
- `low`: 安値（調整前）
- `close`: 終値（調整前）
- `volume`: 取引高（調整前）
- `turnover_value`: 取引代金
- `adjustment_factor`: 調整係数（株式分割等を考慮）
- `adjustment_open`: 調整済み始値
- `adjustment_high`: 調整済み高値
- `adjustment_low`: 調整済み安値
- `adjustment_close`: 調整済み終値
- `adjustment_volume`: 調整済み取引高
- `upper_limit`: ストップ高フラグ（0: 通常、1: ストップ高）
- `lower_limit`: ストップ安フラグ（0: 通常、1: ストップ安）

## モジュール構成

### 1. APIクライアント
- `lib/moo_markets/jquants/client.ex`
  - 株価四本値データ取得用のエンドポイント実装
  - パラメータ: code, date, from, to
  - レスポンスのパース処理

### 2. スキーマ
- `lib/moo_markets/market/daily_quote.ex`
  - データベーススキーマ定義
  - バリデーションルール
  - APIレスポンスからの変換処理

### 3. ジョブ
#### 3.1 初回データ取得ジョブ
- `lib/moo_markets/scheduler/jobs/fetch_historical_daily_quotes_job.ex`
  - 2000年1月1日から現在までの過去データを取得
  - バッチ処理として実装
  - 銘柄コードごとに期間を分割して取得（例：1年単位）
  - エラー発生時のリトライ機能
  - 進捗状況の保存と再開機能
  - Mixタスクとして実装
  - 手動実行可能
  - 進捗状況の可視化

#### 3.2 デイリー更新ジョブ
- `lib/moo_markets/scheduler/jobs/fetch_latest_daily_quotes_job.ex`
  - 前営業日のデータを取得
  - 定期実行（例：毎日16:00）
  - 前営業日の特定（取引カレンダーを参照）
  - エラー時の再試行

### 4. ジョブグループ管理
#### 4.1 データベース設計
```sql
-- ジョブグループテーブル
CREATE TABLE job_groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ジョブテーブルにグループIDを追加
ALTER TABLE jobs ADD COLUMN group_id BIGINT REFERENCES job_groups(id);
```

#### 4.2 モジュール構成
- `lib/moo_markets/scheduler/job_group.ex`
  - ジョブグループのスキーマ定義
  - グループ状態の管理
  - 進捗状況の管理

- `lib/moo_markets/scheduler/jobs/fetch_daily_quotes_group_job.ex`
  - グループジョブの実装
  - 取得対象の銘柄コード一覧の取得
  - 各銘柄コードに対する子ジョブの生成
  - グループ全体の進捗管理

## 実装の考慮点

### 1. データ取得範囲
- 初回取得: 2000年1月1日から現在まで
- 定期更新: 前営業日のデータを取得
- 取得対象: 東証上場銘柄のみ（地方取引所単独上場銘柄は対象外）

### 2. エラーハンドリング
- API制限エラー
- データ欠損時の処理（取引高が存在しない日の処理）
- 重複データの処理
- 異常値の検出と処理
- 2020/10/1のデータ欠損対応

### 3. パフォーマンス最適化
- バッチ処理による効率的なデータ取得
- インデックスを活用した高速な検索
- 不要データのアーカイブ処理
- 銘柄コードごとの並列実行
- グループ単位でのリソース制御

### 4. 監視機能
- データ取得状況のモニタリング
- エラー発生時の通知
- データ品質チェック
- グループ単位での進捗管理
- エラー発生時の影響範囲の特定

## 実装優先順位

1. データベース設計とマイグレーション
2. APIクライアントの実装
3. スキーマの実装
4. ジョブグループ管理の実装
5. 初回データ取得ジョブの実装
6. デイリー更新ジョブの実装
7. エラーハンドリングの実装
8. パフォーマンス最適化
9. 監視機能の実装

## テスト計画

1. ユニットテスト
   - APIクライアント
   - スキーマ
   - ジョブ
   - ジョブグループ管理

2. 統合テスト
   - データ取得フロー
   - エラーハンドリング
   - パフォーマンス
   - グループ実行の動作確認

3. E2Eテスト
   - 定期実行
   - エラー通知
   - データ品質
   - グループ実行の全体フロー 