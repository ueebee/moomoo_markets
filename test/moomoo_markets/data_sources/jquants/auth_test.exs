defmodule MoomooMarkets.DataSources.JQuants.AuthTest do
  use MoomooMarkets.DataCase

  alias MoomooMarkets.DataSources.JQuants.Auth

  alias MoomooMarkets.{
    DataSources.DataSourceCredential
  }

  setup do
    bypass = Bypass.open(port: 4040)
    seed_data = MoomooMarkets.TestSeedHelper.insert_test_seeds()
    Map.put(seed_data, :bypass, bypass)
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

    test "IDトークンが無効でリフレッシュトークンが有効な場合、新しいIDトークンを取得する", %{
      bypass: bypass,
      credential: credential
    } do
      # 有効なリフレッシュトークンを持つクレデンシャルを作成
      valid_refresh_token = "valid_refresh_token"
      refresh_valid_until = DateTime.utc_now() |> DateTime.add(3600) |> DateTime.truncate(:second)

      {:ok, credential} =
        Ecto.Changeset.change(credential, %{
          refresh_token: valid_refresh_token,
          refresh_token_expired_at: refresh_valid_until
        })
        |> Repo.update()

      # Bypass設定
      Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["refreshtoken"] == valid_refresh_token

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
      end)

      assert {:ok, "new_id_token"} = Auth.ensure_valid_id_token(credential.user_id)

      # データベースが更新されていることを確認
      updated_credential = Repo.get!(DataSourceCredential, credential.id)
      assert updated_credential.id_token == "new_id_token"
      assert DateTime.compare(updated_credential.id_token_expired_at, DateTime.utc_now()) == :gt
    end

    test "両方のトークンが無効な場合、新しいトークンを取得する", %{bypass: bypass, credential: credential} do
      # Bypass設定 - リフレッシュトークン取得
      Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
      end)

      # Bypass設定 - IDトークン取得
      Bypass.expect_once(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["refreshtoken"] == "new_refresh_token"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"idToken" => "new_id_token"}))
      end)

      assert {:ok, "new_id_token"} = Auth.ensure_valid_id_token(credential.user_id)

      # データベースが更新されていることを確認
      updated_credential = Repo.get!(DataSourceCredential, credential.id)
      assert updated_credential.refresh_token == "new_refresh_token"
      assert updated_credential.id_token == "new_id_token"

      assert DateTime.compare(updated_credential.refresh_token_expired_at, DateTime.utc_now()) ==
               :gt

      assert DateTime.compare(updated_credential.id_token_expired_at, DateTime.utc_now()) == :gt
    end

    test "認証情報が見つからない場合、エラーを返す" do
      assert {:error, error} = Auth.ensure_valid_id_token(999)
      assert error.code == "CREDENTIAL_NOT_FOUND"
    end

    test "APIエラーの場合、エラーを返す", %{bypass: bypass, credential: credential} do
      # Bypass設定
      Bypass.expect_once(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(401, Jason.encode!(%{"message" => "Invalid credentials"}))
      end)

      assert {:error, error} = Auth.ensure_valid_id_token(credential.user_id)
      assert error.code == "HTTP_401"
    end

    test "APIサーバーがダウンしている場合、エラーを返す", %{bypass: bypass, credential: credential} do
      Bypass.down(bypass)
      assert {:error, error} = Auth.ensure_valid_id_token(credential.user_id)
      assert error.code == "HTTP_ERROR"
    end
  end
end
