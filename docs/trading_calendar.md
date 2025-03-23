# 取引カレンダー機能設計

## 概要
JQuants APIから取引カレンダーデータを取得し、東証およびOSEにおける営業日、休業日、ならびにOSEにおける祝日取引の有無の情報を管理する機能を実装します。

## JQuants API取引カレンダーエンドポイント仕様

### エンドポイント
- `GET https://api.jquants.com/v1/markets/trading_calendar`

### パラメータ
- `holidaydivision`: 休日区分（オプション）
- `from`: 開始日（オプション、YYYYMMDDまたはYYYY-MM-DD形式）
- `to`: 終了日（オプション、YYYYMMDDまたはYYYY-MM-DD形式）

### レスポンス形式
```json
{
  "trading_calendar": [
    {
      "Date": "YYYY-MM-DD",
      "HolidayDivision": "1"
    }
  ]
}
```

### データの制限と特徴
1. データ取得可能期間
   - 2015年3月23日以降のデータが取得可能
   - 将来的な取引日は毎年3月末頃に更新

2. データの特徴
   - 土日祝日は除外
   - `HolidayDivision`は常に"1"の固定値
   - 日付は"YYYY-MM-DD"形式で提供

3. サブスクリプション制限
   - 現在のサブスクリプションでは2015年3月23日以降のデータのみアクセス可能
   - より古いデータは別プランでの提供が必要

### エラーメッセージ
- サブスクリプション制限に抵触する場合：
```json
{
  "message": "Your subscription covers the following dates: YYYY-MM-DD ~ . If you want more data, please check other plans:https://jpx-jquants.com/"
}
```

## 実装状況

### 1. データベース設計 ✅
#### trading_calendars テーブル
```sql
CREATE TABLE trading_calendars (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  holiday_division VARCHAR(50) NOT NULL,
  inserted_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
  UNIQUE(date)
);

CREATE INDEX trading_calendars_date_idx ON trading_calendars(date);
```

### 2. 実装済みモジュール

#### JQuants APIクライアント ✅
- `lib/moo_markets/jquants/client.ex`
  - 取引カレンダーAPIのエンドポイント実装
  - レスポンスのパース処理実装
  - エラーハンドリング実装

#### スキーマ ✅
- `lib/moo_markets/jquants/schemas/trading_calendar.ex`
  - 取引カレンダーデータのスキーマ定義
  - JQuants APIレスポンスの変換処理実装
  - バリデーション処理実装

#### ジョブ ✅
- `lib/moo_markets/scheduler/jobs/fetch_trading_calendar_job.ex`
  - 取引カレンダーデータ取得ジョブの実装
  - 2018年6月1日から翌年末までのデータを取得
  - 基本的なエラーハンドリング実装
  - ログ出力機能実装

### 3. 動作確認済み機能 ✅
- データベーステーブルの作成
- JQuants APIからのデータ取得
- データの保存と重複防止
- 基本的なエラーハンドリング
- 手動実行機能
- スケジューラーへの登録

## 今後の実装予定

### 1. 優先度の高い機能
- サブスクリプションレベルに応じたデータ取得範囲の制御
- エラー通知機能の強化
- 実行ログの詳細化
- データ取得の最適化

### 2. 追加機能
- 祝日取引の有無の情報追加
- データの統計情報
- カスタム休日設定機能
- キャッシュ機能の実装

### 3. エラーハンドリングの強化
- サブスクリプション制限エラーの適切な処理
- 日付範囲バリデーションの強化
- データ整合性の確保
- リトライ機能の実装

## 動作確認手順

### 1. データベースのセットアップ
```elixir
# マイグレーションの実行
mix ecto.migrate
```

### 2. 手動実行
```elixir
# IExシェルで実行
iex> MooMarkets.Scheduler.Jobs.FetchTradingCalendarJob.perform()

# 保存されたデータの確認
iex> alias MooMarkets.JQuants.Schemas.TradingCalendar
iex> alias MooMarkets.Repo
iex> Repo.all(TradingCalendar)
```

## 今後の課題

1. パフォーマンス最適化
   - 大量データの効率的な取得
   - キャッシュ機能の実装
   - インデックスの最適化

2. 運用性の向上
   - 監視機能の強化
   - エラー通知の改善
   - バックアップ/リストア機能
   - サブスクリプション制限の監視と通知

3. ドキュメント整備
   - API仕様書の更新
   - 運用マニュアルの作成
   - トラブルシューティングガイドの作成

