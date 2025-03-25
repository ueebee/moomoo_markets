# テスト

## 概要
MoomooMarketsでは、ExUnitとBypassを使用してテストを実装しています。特に外部APIとの通信を含むテストでは、Bypassを使用してモックを実装しています。

## テストの種類

### 1. データマッピングテスト
```elixir
describe "map_to_stock/3" do
  test "正常系: APIレスポンスをStockにマッピング" do
    today = Date.utc_today()
    now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    info = %{
      "Code" => "1234",
      "CompanyName" => "テスト株式会社",
      "CompanyNameEnglish" => "Test Corp",
      "Sector17Code" => "S1",
      "Sector17CodeName" => "セクター1",
      "Sector33Code" => "S1-1",
      "Sector33CodeName" => "サブセクター1",
      "ScaleCategory" => "大規模",
      "MarketCode" => "M1",
      "MarketCodeName" => "市場1",
      "MarginCode" => "MG1",
      "MarginCodeName" => "証拠金1"
    }

    assert {:ok, stock} = Stock.map_to_stock(info, today, now)
    assert stock.code == "1234"
    assert stock.name == "テスト株式会社"
    assert stock.name_en == "Test Corp"
    assert stock.sector_code == "S1"
    assert stock.sector_name == "セクター1"
    assert stock.sub_sector_code == "S1-1"
    assert stock.sub_sector_name == "サブセクター1"
    assert stock.scale_category == "大規模"
    assert stock.market_code == "M1"
    assert stock.market_name == "市場1"
    assert stock.margin_code == "MG1"
    assert stock.margin_name == "証拠金1"
    assert stock.effective_date == today
    assert stock.inserted_at == now
    assert stock.updated_at == now
  end

  test "異常系: 必須フィールドが欠けている場合" do
    today = Date.utc_today()
    now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    info = %{
      "CompanyName" => "テスト株式会社"
    }

    assert {:error, %Error{code: :invalid_data, message: "Missing required field: Code"}} =
             Stock.map_to_stock(info, today, now)
  end
end
```

### 2. API通信テスト
```elixir
describe "fetch_listed_info/0" do
  test "正常系: 上場情報を取得して保存" do
    bypass = Bypass.open()
    user = insert(:user)
    data_source = insert(:data_source, base_url: "http://localhost:#{bypass.port}")
    credential = insert(:data_source_credential, user: user, data_source: data_source)

    Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
      conn
      |> Plug.Conn.resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
    end)

    Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
      conn
      |> Plug.Conn.resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
    end)

    Bypass.expect_once(bypass, "GET", "/listed/info", fn conn ->
      conn
      |> Plug.Conn.resp(200, Jason.encode!(%{"info" => [%{"Code" => "1234", "CompanyName" => "テスト株式会社"}]}))
    end)

    assert {:ok, stocks} = Stock.fetch_listed_info()
    assert length(stocks) == 1
    assert hd(stocks).code == "1234"
    assert hd(stocks).name == "テスト株式会社"
  end

  test "異常系: APIエラー" do
    bypass = Bypass.open()
    user = insert(:user)
    data_source = insert(:data_source, base_url: "http://localhost:#{bypass.port}")
    credential = insert(:data_source_credential, user: user, data_source: data_source)

    Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
      conn
      |> Plug.Conn.resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
    end)

    Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
      conn
      |> Plug.Conn.resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
    end)

    Bypass.expect_once(bypass, "GET", "/listed/info", fn conn ->
      conn
      |> Plug.Conn.resp(500, Jason.encode!(%{"message" => "Internal Server Error"}))
    end)

    assert {:error, %Error{code: :api_error}} = Stock.fetch_listed_info()
  end
end
```

## テストのベストプラクティス

1. **テストの構造化**
   - `describe`ブロックで関連するテストをグループ化
   - テストケースを「正常系」と「異常系」に分類

2. **モックの使用**
   - 外部APIの通信は必ずBypassでモック
   - モックの期待値を明確に定義

3. **データの準備**
   - テストデータは`insert/1`を使用して作成
   - 必要な関連データも適切に作成

4. **アサーション**
   - 戻り値の型と内容を厳密に検証
   - エラーケースでは適切なエラー型とメッセージを検証

## テストの実行

```bash
# すべてのテストを実行
mix test

# 特定のテストファイルを実行
mix test test/moomoo_markets/data_sources/jquants/stock_test.exs

# 特定のテストケースを実行
mix test test/moomoo_markets/data_sources/jquants/stock_test.exs:123
``` 