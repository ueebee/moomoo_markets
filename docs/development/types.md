# 型の定義と使用方法

## 概要
MoomooMarketsでは、Dialyzerの型チェックを活用して、型の安全性を確保しています。各モジュールで使用する型は明示的に定義し、関数の引数と戻り値の型を指定しています。

## 型の定義

### 1. スキーマの型定義
```elixir
@type t :: %__MODULE__{
  code: String.t(),
  name: String.t(),
  name_en: String.t() | nil,
  sector_code: String.t() | nil,
  sector_name: String.t() | nil,
  sub_sector_code: String.t() | nil,
  sub_sector_name: String.t() | nil,
  scale_category: String.t() | nil,
  market_code: String.t() | nil,
  market_name: String.t() | nil,
  margin_code: String.t() | nil,
  margin_name: String.t() | nil,
  effective_date: Date.t(),
  inserted_at: NaiveDateTime.t(),
  updated_at: NaiveDateTime.t()
}
```

### 2. 関数の型定義
```elixir
@spec fetch_listed_info() :: {:ok, [t()]} | {:error, Error.t()}
def fetch_listed_info do
  # ...
end

@spec map_to_stock(Types.listed_info(), Date.t(), NaiveDateTime.t()) :: {:ok, map()} | {:error, Error.t()}
defp map_to_stock(info, today, now) do
  # ...
end
```

### 3. カスタム型の定義
```elixir
defmodule MoomooMarkets.DataSources.JQuants.Types do
  @type listed_info :: %{
    required(String.t()) => String.t(),
    optional(String.t()) => String.t() | nil
  }
end
```

## 型の使用

### 1. 戻り値の型
- 成功時: `{:ok, value}`
- エラー時: `{:error, Error.t()}`

### 2. オプショナルな値
- `nil`を許容する場合は`| nil`を付加
- 例: `String.t() | nil`

### 3. リストの型
- 要素の型を`[]`で囲む
- 例: `[String.t()]`

## 型チェックの実行

```bash
# 型チェックを実行
mix dialyzer

# 型チェックの警告を表示
mix dialyzer --format short
```

## 型のベストプラクティス

1. **明示的な型定義**
   - すべての関数で`@spec`を使用
   - 複雑な型は別モジュールで定義

2. **型の再利用**
   - 共通の型は`Types`モジュールで定義
   - 型のエイリアスを適切に使用

3. **型の厳密性**
   - 可能な限り具体的な型を指定
   - オプショナルな値は明示的に`| nil`を付加

4. **型の検証**
   - 定期的に`mix dialyzer`を実行
   - 型の警告は必ず修正

## 型の例

### 1. 基本的な型
```elixir
@type t :: %__MODULE__{
  id: integer(),
  name: String.t(),
  age: integer() | nil
}
```

### 2. 複雑な型
```elixir
@type response :: %{
  status: :ok | :error,
  data: map() | nil,
  error: Error.t() | nil
}
```

### 3. リストの型
```elixir
@type list :: [%{
  id: integer(),
  name: String.t()
}]
``` 