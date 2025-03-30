defmodule MoomooMarkets.DataSources.JQuants.StockTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.DataSources.JQuants.{Stock, Error}
  alias MoomooMarkets.DataSources.DataSourceCredential
  alias MoomooMarkets.Encryption

  setup do
    # テストデータの登録
    seed_data = MoomooMarkets.TestSeedHelper.insert_test_seeds()
    # data_sourceをロード
    credential = Repo.preload(seed_data.credential, :data_source)
    Map.put(seed_data, :credential, credential)
  end

  describe "fetch_listed_info/0" do
    test "successfully fetches and saves listed info", %{credential: _credential} do
      # API呼び出し
      assert {:ok, [2]} = Stock.fetch_listed_info()

      # データベースの検証
      stocks = Repo.all(Stock)
      assert length(stocks) == 2

      # 最初のレコードの検証（トヨタ自動車のデータ）
      [first_stock | _] = stocks
      assert first_stock.code == "7203"
      assert first_stock.name == "トヨタ自動車"
      assert first_stock.sector_code == "3"
      assert first_stock.market_code == "0111"
      assert first_stock.effective_date == Date.utc_today()
      assert first_stock.inserted_at != nil
      assert first_stock.updated_at != nil
    end

    test "handles API errors", %{credential: credential} do
      # 認証情報を無効なものに変更
      {:ok, _} = Repo.update(DataSourceCredential.changeset(
        credential,
        %{
          encrypted_credentials: Encryption.encrypt(
            Jason.encode!(%{
              "mailaddress" => "test@example.com",
              "password" => "wrong_password"
            })
          )
        }
      ))

      # API呼び出し
      assert {:error, %Error{
        code: "HTTP_400",
        message: "Failed to get refresh token: mailaddress or password is incorrect.",
        details: nil
      }} = Stock.fetch_listed_info()

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(Stock) == []
    end

    test "handles invalid response format", %{credential: credential} do
      # 認証情報を無効なものに変更
      {:ok, _} = Repo.update(DataSourceCredential.changeset(
        credential,
        %{
          encrypted_credentials: Encryption.encrypt(
            Jason.encode!(%{
              "mailaddress" => "forbidden@example.com",
              "password" => "test_password"
            })
          )
        }
      ))

      # API呼び出し
      assert {:error, %Error{
        code: "HTTP_403",
        message: "Failed to get refresh token: Missing Authentication Token. The method or resources may not be supported.",
        details: nil
      }} = Stock.fetch_listed_info()

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(Stock) == []
    end
  end
end
