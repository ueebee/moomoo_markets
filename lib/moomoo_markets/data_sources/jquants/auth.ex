defmodule MoomooMarkets.DataSources.JQuants.Auth do
  @moduledoc """
  J-Quants APIの認証処理
  """

  alias MoomooMarkets.DataSources.JQuants.{Types, Error}
  alias MoomooMarkets.{Encryption, Repo, DataSources.DataSource, DataSources.DataSourceCredential}
  import Ecto.Query

  @base_url "https://api.jquants.com/v1"
  @refresh_token_path "/token/auth_user"
  @id_token_path "/token/auth_refresh"

  @doc """
  有効なIDトークンを取得します。
  必要に応じてトークンの更新を行います。
  """
  @spec ensure_valid_id_token(integer()) :: {:ok, String.t()} | {:error, Error.t()}
  def ensure_valid_id_token(user_id) do
    with {:ok, credential} <- get_data_source_credential(user_id) do
      cond do
        # IDトークンが有効な場合
        is_id_token_valid?(credential) ->
          {:ok, credential.id_token}

        # リフレッシュトークンが有効な場合
        is_refresh_token_valid?(credential) ->
          with {:ok, token} <- get_id_token(credential.refresh_token),
               {:ok, _credential} <- update_id_token(credential, token) do
            {:ok, token.id_token}
          end

        # どちらのトークンも無効な場合
        true ->
          with {:ok, credentials} <- get_credentials(user_id),
               {:ok, refresh_token} <- get_refresh_token(credentials),
               {:ok, credential_with_refresh} <- update_refresh_token(credential, refresh_token),
               {:ok, id_token} <- get_id_token(refresh_token.refresh_token),
               {:ok, _credential} <- update_id_token(credential_with_refresh, id_token) do
            {:ok, id_token.id_token}
          end
      end
    end
  end

  @doc """
  ユーザーのJ-Quants認証情報を取得します
  """
  @spec get_credentials(integer()) :: {:ok, Types.credentials()} | {:error, Error.t()}
  def get_credentials(user_id) do
    query =
      from c in DataSourceCredential,
        join: d in DataSource,
        on: c.data_source_id == d.id,
        where: c.user_id == ^user_id and d.provider_type == "jquants",
        select: c.encrypted_credentials

    case Repo.one(query) do
      nil ->
        {:error, %Error{
          message: "J-Quants credentials not found for user",
          code: "CREDENTIALS_NOT_FOUND"
        }}

      encrypted_credentials ->
        case Jason.decode(Encryption.decrypt(encrypted_credentials)) do
          {:ok, credentials} ->
            {:ok, credentials}

          {:error, _} ->
            {:error, %Error{
              message: "Failed to decrypt credentials",
              code: "DECRYPT_ERROR"
            }}
        end
    end
  end

  @doc """
  リフレッシュトークンを取得します
  """
  @spec get_refresh_token(Types.credentials()) :: {:ok, Types.t()} | {:error, Error.t()}
  def get_refresh_token(credentials) do
    with {:ok, response} <- request_refresh_token(credentials),
         {:ok, token} <- parse_refresh_token_response(response) do
      {:ok, token}
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  IDトークンを取得します
  """
  @spec get_id_token(String.t()) :: {:ok, Types.t()} | {:error, Error.t()}
  def get_id_token(refresh_token) do
    with {:ok, response} <- request_id_token(refresh_token),
         {:ok, token} <- parse_id_token_response(response) do
      {:ok, token}
    else
      {:error, error} -> {:error, error}
    end
  end

  # Private functions

  defp get_data_source_credential(user_id) do
    query =
      from c in DataSourceCredential,
        join: d in DataSource,
        on: c.data_source_id == d.id,
        where: c.user_id == ^user_id and d.provider_type == "jquants",
        select: c

    case Repo.one(query) do
      nil ->
        {:error, %Error{
          message: "Data source credential not found",
          code: "CREDENTIAL_NOT_FOUND"
        }}

      credential ->
        {:ok, credential}
    end
  end

  defp update_refresh_token(credential, token) do
    credential
    |> Ecto.Changeset.change(%{
      refresh_token: token.refresh_token,
      refresh_token_expired_at: DateTime.truncate(token.refresh_token_expired_at, :second)
    })
    |> Repo.update()
    |> case do
      {:ok, credential} -> {:ok, credential}
      {:error, _} -> {:error, %Error{message: "Failed to update refresh token", code: "UPDATE_ERROR"}}
    end
  end

  defp update_id_token(credential, token) do
    credential
    |> Ecto.Changeset.change(%{
      id_token: token.id_token,
      id_token_expired_at: DateTime.truncate(token.id_token_expired_at, :second)
    })
    |> Repo.update()
    |> case do
      {:ok, credential} -> {:ok, credential}
      {:error, _} -> {:error, %Error{message: "Failed to update ID token", code: "UPDATE_ERROR"}}
    end
  end

  defp is_id_token_valid?(credential) do
    credential.id_token != nil &&
      credential.id_token_expired_at != nil &&
      DateTime.compare(credential.id_token_expired_at, DateTime.utc_now()) == :gt
  end

  defp is_refresh_token_valid?(credential) do
    credential.refresh_token != nil &&
      credential.refresh_token_expired_at != nil &&
      DateTime.compare(credential.refresh_token_expired_at, DateTime.utc_now()) == :gt
  end

  defp request_refresh_token(credentials) do
    url = @base_url <> @refresh_token_path

    case Req.post(url, json: credentials) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: %{"message" => message}}} ->
        {:error, %Error{
          message: "Failed to get refresh token: #{message}",
          code: "HTTP_#{status}"
        }}

      {:ok, %Req.Response{status: status}} ->
        {:error, %Error{
          message: "Failed to get refresh token",
          code: "HTTP_#{status}"
        }}

      {:error, error} ->
        {:error, %Error{
          message: "HTTP request failed: #{inspect(error)}",
          code: "HTTP_ERROR"
        }}
    end
  end

  defp request_id_token(refresh_token) do
    url = @base_url <> @id_token_path <> "?refreshtoken=#{refresh_token}"

    case Req.post(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: %{"message" => message}}} ->
        {:error, %Error{
          message: "Failed to get ID token: #{message}",
          code: "HTTP_#{status}"
        }}

      {:ok, %Req.Response{status: status}} ->
        {:error, %Error{
          message: "Failed to get ID token",
          code: "HTTP_#{status}"
        }}

      {:error, error} ->
        {:error, %Error{
          message: "HTTP request failed: #{inspect(error)}",
          code: "HTTP_ERROR"
        }}
    end
  end

  defp parse_refresh_token_response(%{"refreshToken" => refresh_token}) do
    {:ok, %Types{
      refresh_token: refresh_token,
      refresh_token_expired_at: DateTime.add(DateTime.utc_now(), 7 * 24 * 60 * 60, :second)
    }}
  end

  defp parse_refresh_token_response(_) do
    {:error, %Error{
      message: "Invalid refresh token response",
      code: "INVALID_RESPONSE"
    }}
  end

  defp parse_id_token_response(%{"idToken" => id_token}) do
    {:ok, %Types{
      id_token: id_token,
      id_token_expired_at: DateTime.add(DateTime.utc_now(), 24 * 60 * 60, :second)
    }}
  end

  defp parse_id_token_response(_) do
    {:error, %Error{
      message: "Invalid ID token response",
      code: "INVALID_RESPONSE"
    }}
  end
end
