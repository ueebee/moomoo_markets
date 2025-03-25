# エラーハンドリング

## 概要
MoomooMarketsでは、アプリケーション全体で一貫したエラーハンドリングを実現するため、カスタムエラー型を使用しています。

## エラー型の定義

### 基本構造
```elixir
defmodule MoomooMarkets.DataSources.JQuants.Error do
  defexception [:message, :code, :details]

  @type t :: %__MODULE__{
    code: atom(),
    message: String.t(),
    details: map() | nil
  }

  def error(code, message, details \\ nil) do
    %__MODULE__{code: code, message: message, details: details}
  end
end
```

### エラーコード
- `:invalid_data` - データの形式が不正
- `:invalid_response` - APIレスポンスの形式が不正
- `:json_error` - JSONのパースに失敗
- `:api_error` - APIリクエストが失敗
- `:http_error` - HTTPリクエストが失敗
- `:credential_not_found` - 認証情報が見つからない
- `:database_error` - データベース操作が失敗

## エラーハンドリングの実装

### 1. データ検証
```elixir
defp get_required_field(map, field) do
  case Map.get(map, field) do
    nil -> {:error, Error.error(:invalid_data, "Missing required field: #{field}")}
    value -> {:ok, value}
  end
end
```

### 2. APIレスポンスの処理
```elixir
defp parse_response(%{"info" => listed_info}) when is_list(listed_info) do
  {:ok, listed_info}
end

defp parse_response(response) when is_binary(response) do
  case Jason.decode(response) do
    {:ok, %{"info" => listed_info}} when is_list(listed_info) ->
      {:ok, listed_info}
    {:ok, _} ->
      {:error, Error.error(:invalid_response, "Invalid response format")}
    {:error, reason} ->
      {:error, Error.error(:json_error, "Failed to parse JSON", %{reason: reason})}
  end
end
```

### 3. データベース操作のエラーハンドリング
```elixir
defp save_chunk(chunk, {:ok, acc}) do
  case Repo.insert_all(__MODULE__, chunk, on_conflict: :replace_all, conflict_target: [:code, :effective_date]) do
    {n, _} when is_integer(n) -> {:cont, {:ok, [n | acc]}}
    {:error, reason} -> {:halt, {:error, Error.error(:database_error, "Failed to save stocks", %{reason: reason})}}
  end
end
```

## エラーハンドリングのベストプラクティス

1. **型の定義**
   - すべての関数で戻り値の型を明示的に定義
   - エラー型を含む戻り値の型を明確に指定

2. **エラーの伝播**
   - `with`式を使用してエラーを適切に伝播
   - エラーが発生した場合は早期に処理を中断

3. **エラーメッセージ**
   - 具体的で分かりやすいエラーメッセージを提供
   - 必要に応じて詳細情報を含める

4. **テスト**
   - エラーケースを含むテストを実装
   - エラーメッセージとコードの検証

## 使用例

```elixir
def fetch_listed_info do
  with {:ok, %{credential: credential, base_url: base_url}} <- get_credential(),
       {:ok, id_token} <- Auth.ensure_valid_id_token(credential.user_id),
       {:ok, response} <- make_request(%{credential: credential, base_url: base_url}, id_token),
       {:ok, data} <- parse_response(response) do
    save_listed_info(data)
  else
    {:error, reason} -> {:error, reason}
  end
end
``` 