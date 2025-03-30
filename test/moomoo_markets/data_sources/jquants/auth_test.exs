defmodule MoomooMarkets.DataSources.JQuants.AuthTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.DataSources.JQuants.Auth

  alias MoomooMarkets.{
    DataSources.DataSourceCredential,
    Encryption
  }

  setup do
    # テストデータの登録
    seed_data = MoomooMarkets.TestSeedHelper.insert_test_seeds()
    # data_sourceをロード
    credential = Repo.preload(seed_data.credential, :data_source)
    Map.put(seed_data, :credential, credential)
  end

  describe "ensure_valid_id_token/1" do
    test "IDトークンが有効な場合、そのトークンを返す", %{credential: credential} do
      # 有効なIDトークンを持つクレデンシャルを作成
      valid_id_token = "valid_id_token"
      valid_until = DateTime.utc_now() |> DateTime.add(3600) |> DateTime.truncate(:second)

      {:ok, credential} =
        Ecto.Changeset.change(credential, %{
          id_token: valid_id_token,
          id_token_expired_at: valid_until
        })
        |> Repo.update()

      assert {:ok, ^valid_id_token} = Auth.ensure_valid_id_token(credential.user_id)
    end

    test "IDトークンが無効でリフレッシュトークンが有効な場合、新しいIDトークンを取得する", %{credential: credential} do
      # 有効なリフレッシュトークンを持つクレデンシャルを作成
      valid_refresh_token = "new_refresh_token"  # モックサーバーの正常系のトークン
      refresh_valid_until = DateTime.utc_now() |> DateTime.add(3600) |> DateTime.truncate(:second)

      {:ok, credential} =
        Ecto.Changeset.change(credential, %{
          refresh_token: valid_refresh_token,
          refresh_token_expired_at: refresh_valid_until
        })
        |> Repo.update()

      result = Auth.ensure_valid_id_token(credential.user_id)
      assert {:ok, "new_id_token"} = result

      # データベースが更新されていることを確認
      updated_credential = Repo.get!(DataSourceCredential, credential.id)
      assert updated_credential.id_token == "new_id_token"
      assert DateTime.compare(updated_credential.id_token_expired_at, DateTime.utc_now()) == :gt
    end

    test "両方のトークンが無効な場合、新しいトークンを取得する", %{credential: credential} do
      # テスト用の認証情報を使用
      {:ok, credential} =
        Ecto.Changeset.change(credential, %{
          encrypted_credentials: Encryption.encrypt(Jason.encode!(%{
            mailaddress: "test@example.com",
            password: "test_password"
          }))
        })
        |> Repo.update()

      assert {:ok, "new_id_token"} = Auth.ensure_valid_id_token(credential.user_id)

      # データベースが更新されていることを確認
      updated_credential = Repo.get!(DataSourceCredential, credential.id)
      assert updated_credential.refresh_token == "new_refresh_token"
      assert updated_credential.id_token == "new_id_token"

      assert DateTime.compare(updated_credential.refresh_token_expired_at, DateTime.utc_now()) == :gt
      assert DateTime.compare(updated_credential.id_token_expired_at, DateTime.utc_now()) == :gt
    end

    test "認証情報が見つからない場合、エラーを返す" do
      assert {:error, error} = Auth.ensure_valid_id_token(9999999)
      assert error.code == "CREDENTIAL_NOT_FOUND"
    end

    test "APIエラーの場合、エラーを返す", %{credential: credential} do
      # 403エラーを発生させるための認証情報
      {:ok, credential} =
        Ecto.Changeset.change(credential, %{
          encrypted_credentials: Encryption.encrypt(Jason.encode!(%{
            mailaddress: "forbidden@example.com",
            password: "test_password"
          }))
        })
        |> Repo.update()

      assert {:error, error} = Auth.ensure_valid_id_token(credential.user_id)
      assert error.code == "HTTP_403"
    end

    test "APIサーバーがダウンしている場合、エラーを返す", %{credential: credential} do
      # 無効なベースURLを設定してAPIサーバーがダウンしている状態をシミュレート
      {:ok, _} = Repo.update(Ecto.Changeset.change(credential.data_source, %{
        base_url: "http://invalid-host:4444"
      }))

      assert {:error, error} = Auth.ensure_valid_id_token(credential.user_id)
      assert error.code == "HTTP_ERROR"
    end
  end
end
