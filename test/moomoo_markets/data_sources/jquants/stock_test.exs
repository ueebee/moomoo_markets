defmodule MoomooMarkets.DataSources.JQuants.StockTest do
  use MoomooMarkets.DataCase
  import Plug.Conn

  alias MoomooMarkets.DataSources.JQuants.{Stock, Error}
  alias MoomooMarkets.{Accounts.User, DataSources.DataSource, DataSources.DataSourceCredential, Encryption}

  setup do
    bypass = Bypass.open(port: 4040)

    # ユーザーの作成
    {:ok, user} =
      Repo.insert(%User{
        email: "test@example.com",
        hashed_password: "dummy_hashed_password"
      })

    # データソースの作成
    {:ok, data_source} =
      Repo.insert(%DataSource{
        name: "J-Quants",
        provider_type: "jquants",
        base_url: "http://localhost:4040"
      })

    # 認証情報の作成
    encrypted_credentials =
      Encryption.encrypt(
        Jason.encode!(%{
          "mailaddress" => "test@example.com",
          "password" => "password"
        })
      )

    {:ok, credential} =
      Repo.insert(%DataSourceCredential{
        user_id: user.id,
        data_source_id: data_source.id,
        encrypted_credentials: encrypted_credentials
      })

    %{
      bypass: bypass,
      data_source: data_source,
      credential: credential,
      user_id: user.id
    }
  end

  describe "fetch_listed_info/0" do
    test "successfully fetches and saves listed info", %{bypass: bypass} do
      # リフレッシュトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
      end)

      # IDトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["refreshtoken"] == "new_refresh_token"

        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
      end)

      # モックのレスポンスを設定
      mock_response = %{
        "info" => [
          %{
            "Date" => "2024-03-25",
            "Code" => "1301",
            "CompanyName" => "極洋",
            "CompanyNameEnglish" => "Kyokuyo Co., Ltd.",
            "Sector17Code" => "2050",
            "Sector17CodeName" => "水産・農林業",
            "Sector33Code" => "2050",
            "Sector33CodeName" => "水産・農林業",
            "ScaleCategory" => "TOPIX Mid400",
            "MarketCode" => "プライム",
            "MarketCodeName" => "プライム市場",
            "MarginCode" => "1",
            "MarginCodeName" => "信用"
          },
          %{
            "Date" => "2024-03-25",
            "Code" => "1302",
            "CompanyName" => "日本水産",
            "CompanyNameEnglish" => "Nippon Suisan Kaisha, Ltd.",
            "Sector17Code" => "2050",
            "Sector17CodeName" => "水産・農林業",
            "Sector33Code" => "2050",
            "Sector33CodeName" => "水産・農林業",
            "ScaleCategory" => "TOPIX Mid400",
            "MarketCode" => "プライム",
            "MarketCodeName" => "プライム市場",
            "MarginCode" => "1",
            "MarginCodeName" => "信用"
          }
        ]
      }

      # Bypassでモックのエンドポイントを設定
      Bypass.expect_once(bypass, "GET", "/listed/info", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(mock_response))
      end)

      # API呼び出し
      assert {:ok, [2]} = Stock.fetch_listed_info()

      # データベースの検証
      stocks = Repo.all(Stock)
      assert length(stocks) == 2

      # 最初のレコードの検証
      [first_stock | _] = stocks
      assert first_stock.code == "1301"
      assert first_stock.name == "極洋"
      assert first_stock.sector_code == "2050"
      assert first_stock.market_code == "プライム"
      assert first_stock.effective_date == Date.utc_today()
      assert first_stock.inserted_at != nil
      assert first_stock.updated_at != nil
    end

    test "handles API errors", %{bypass: bypass} do
      # リフレッシュトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
      end)

      # IDトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["refreshtoken"] == "new_refresh_token"

        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
      end)

      # 認証エラー (401) のモック
      Bypass.expect_once(bypass, "GET", "/listed/info", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(401, Jason.encode!(%{"message" => "The incoming token is invalid or expired."}))
      end)

      # API呼び出し
      assert {:error, %Error{
        code: :api_error,
        message: "API request failed",
        details: %{
          status: 401,
          body: %{"message" => "The incoming token is invalid or expired."}
        }
      }} = Stock.fetch_listed_info()

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(Stock) == []
    end

    test "handles invalid response format", %{bypass: bypass} do
      # リフレッシュトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
      end)

      # IDトークン取得のモック
      Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["refreshtoken"] == "new_refresh_token"

        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
      end)

      # 不正なレスポンス形式のモック
      Bypass.expect_once(bypass, "GET", "/listed/info", fn conn ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(%{"invalid_key" => []}))
      end)

      # API呼び出し
      assert {:error, %Error{
        code: :invalid_response,
        message: "Invalid response format"
      }} = Stock.fetch_listed_info()

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(Stock) == []
    end
  end

end
