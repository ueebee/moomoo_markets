# データソースクライアント設計

## ディレクトリ構造

```
lib/
  moomoo_markets/
    data_sources/
      # 共通のインターフェースと型定義
      client.ex           # 共通のクライアントビヘイビア
      types.ex           # 共通の型定義
      error.ex           # 共通のエラー定義
      
      # 各データソースの実装
      jquants/
        client.ex        # J-Quants APIクライアント
        types.ex         # J-Quants固有の型定義
        error.ex         # J-Quants固有のエラー定義
        auth.ex          # 認証関連の処理
        rate_limit.ex    # レート制限の管理
      
      yfinance/
        client.ex        # yfinance APIクライアント
        types.ex         # yfinance固有の型定義
        error.ex         # yfinance固有のエラー定義
        auth.ex          # 認証関連の処理
        rate_limit.ex    # レート制限の管理
```

## 設計方針

### 1. 共通インターフェース
- すべてのデータソースクライアントが実装すべき共通のインターフェースを定義
- 型の安全性を確保
- テストの容易さを確保

```elixir
# lib/moomoo_markets/data_sources/client.ex
defmodule MoomooMarkets.DataSources.Client do
  @callback fetch_data(any(), keyword()) :: {:ok, any()} | {:error, any()}
  @callback refresh_token(any()) :: {:ok, any()} | {:error, any()}
end
```

### 2. 関心の分離
- 各データソース固有の実装を分離
- コードの保守性向上
- テストの独立性確保

```elixir
# lib/moomoo_markets/data_sources/jquants/client.ex
defmodule MoomooMarkets.DataSources.JQuants.Client do
  @behaviour MoomooMarkets.DataSources.Client
  
  # 実装
end
```

### 3. 型定義
- 共通の型定義による一貫性の確保
- 新しいデータソースの追加が容易

```elixir
# lib/moomoo_markets/data_sources/types.ex
defmodule MoomooMarkets.DataSources.Types do
  @type data_source :: :jquants | :yfinance
  @type credentials :: map()
  @type response :: map()
end
```

### 4. エラーハンドリング
- エラー処理の一貫性
- デバッグのしやすさ

```elixir
# lib/moomoo_markets/data_sources/error.ex
defmodule MoomooMarkets.DataSources.Error do
  defexception [:message, :code]
end
```

## 実装例

### J-Quants APIクライアント
```elixir
# lib/moomoo_markets/data_sources/jquants/client.ex
defmodule MoomooMarkets.DataSources.JQuants.Client do
  @behaviour MoomooMarkets.DataSources.Client
  alias MoomooMarkets.DataSources.JQuants.{Auth, RateLimit}

  def fetch_data(credentials, opts) do
    with {:ok, token} <- Auth.get_token(credentials),
         :ok <- RateLimit.check_limit(),
         {:ok, response} <- make_request(token, opts) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def refresh_token(credentials) do
    Auth.refresh_token(credentials)
  end
end
```

## 利点

1. **コードの再利用性**
   - 共通のインターフェースと型定義
   - 共通のエラーハンドリング
   - 共通のユーティリティ関数

2. **テストの容易さ**
   - インターフェースベースのテスト
   - モックの作成が容易
   - テストの独立性

3. **拡張性**
   - 新しいデータソースの追加が容易
   - 共通の機能の追加が容易
   - 型の安全性

4. **保守性**
   - 明確な責任の分離
   - コードの一貫性
   - エラーハンドリングの統一

5. **Phoenixのベストプラクティス**
   - コンテキストベースの構造
   - 適切なモジュール粒度
   - 明確な責任の分離

## 次のステップ

1. J-Quants APIクライアントの実装
   - 認証処理
   - レート制限
   - エラーハンドリング

2. テストの実装
   - ユニットテスト
   - 統合テスト
   - モックの作成

3. ドキュメントの整備
   - API仕様書
   - 使用例
   - エラーコード一覧 