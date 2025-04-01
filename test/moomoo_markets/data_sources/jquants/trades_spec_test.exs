defmodule MoomooMarkets.DataSources.JQuants.TradesSpecTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.DataSources.JQuants.{TradesSpec, Error}
  alias MoomooMarkets.DataSources.DataSourceCredential
  alias MoomooMarkets.Encryption

  setup do
    # テストデータの登録
    seed_data = MoomooMarkets.TestSeedHelper.insert_test_seeds()
    # data_sourceをロード
    credential = Repo.preload(seed_data.credential, :data_source)
    Map.put(seed_data, :credential, credential)
  end

  describe "available_sections/0" do
    test "returns list of available market sections" do
      sections = TradesSpec.available_sections()
      assert length(sections) == 8
      assert "TSEPrime" in sections
      assert "TSEStandard" in sections
      assert "TSEContinuous" in sections
      assert "TSE1st" in sections
      assert "TSE2nd" in sections
      assert "TSEJASDAQ" in sections
      assert "TSEJASDAQStandard" in sections
      assert "TSEJASDAQGrowth" in sections
    end
  end

  describe "valid_section?/1" do
    test "returns true for valid market sections" do
      assert TradesSpec.valid_section?("TSEPrime")
      assert TradesSpec.valid_section?("TSEStandard")
      assert TradesSpec.valid_section?("TSEContinuous")
    end

    test "returns false for invalid market sections" do
      refute TradesSpec.valid_section?("InvalidSection")
      refute TradesSpec.valid_section?("")
      refute TradesSpec.valid_section?(nil)
    end
  end

  describe "fetch_trades_spec/3" do
    test "successfully fetches and saves trades spec data", %{credential: _credential} do
      from_date = ~D[2024-03-24]
      to_date = ~D[2024-03-25]
      section = "TSEPrime"

      assert {:ok, %{count: count}} = TradesSpec.fetch_trades_spec(section, from_date, to_date)
      assert count > 0

      # データベースに保存されたデータを検証
      trades_specs = Repo.all(TradesSpec)
      assert length(trades_specs) > 0

      # 最初のレコードの検証
      [first_spec | _] = trades_specs
      assert first_spec.section == section
      assert first_spec.published_date == from_date
      assert first_spec.start_date == from_date
      assert first_spec.end_date == to_date
      assert is_number(first_spec.total_sales)
      assert is_number(first_spec.total_purchases)
      assert is_number(first_spec.total_balance)
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

      from_date = ~D[2024-03-24]
      to_date = ~D[2024-03-25]
      section = "TSEPrime"

      assert {:error, %Error{
        code: "HTTP_400",
        message: "Failed to get refresh token: mailaddress or password is incorrect.",
        details: nil
      }} = TradesSpec.fetch_trades_spec(section, from_date, to_date)

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(TradesSpec) == []
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

      from_date = ~D[2024-03-24]
      to_date = ~D[2024-03-25]
      section = "TSEPrime"

      assert {:error, %Error{
        code: "HTTP_403",
        message: "Failed to get refresh token: Missing Authentication Token. The method or resources may not be supported.",
        details: nil
      }} = TradesSpec.fetch_trades_spec(section, from_date, to_date)

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(TradesSpec) == []
    end

    test "handles invalid market section" do
      from_date = ~D[2024-03-24]
      to_date = ~D[2024-03-25]
      section = "InvalidSection"

      assert {:error, %Error{
        code: :api_error,
        message: "API request failed",
        details: %{status: 400, message: "Invalid market section"}
      }} = TradesSpec.fetch_trades_spec(section, from_date, to_date)

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(TradesSpec) == []
    end

    test "handles date range validation" do
      from_date = ~D[2024-03-25]
      to_date = ~D[2024-03-24]  # 終了日が開始日より前
      section = "TSEPrime"

      assert {:error, %Error{
        code: :api_error,
        message: "API request failed",
        details: %{status: 400, message: "Invalid date range"}
      }} = TradesSpec.fetch_trades_spec(section, from_date, to_date)

      # データベースにレコードが保存されていないことを確認
      assert Repo.all(TradesSpec) == []
    end
  end
end
