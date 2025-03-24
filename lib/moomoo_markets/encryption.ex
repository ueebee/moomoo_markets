defmodule MoomooMarkets.Encryption do
  @moduledoc """
  Provides encryption and decryption functionality for sensitive data.
  Uses Phoenix.Token for encryption.
  """

  @doc """
  Encrypts the given data using Phoenix.Token.
  Returns the encrypted data as a binary.
  """
  def encrypt(data) when is_binary(data) do
    Phoenix.Token.sign(
      MoomooMarketsWeb.Endpoint,
      get_secret_key_base(),
      data,
      max_age: :infinity
    )
  end

  @doc """
  Decrypts the given encrypted data using Phoenix.Token.
  Returns the decrypted data as a string.
  """
  def decrypt(encrypted_data) when is_binary(encrypted_data) do
    case Phoenix.Token.verify(
      MoomooMarketsWeb.Endpoint,
      get_secret_key_base(),
      encrypted_data,
      max_age: :infinity
    ) do
      {:ok, data} -> data
      {:error, _} -> nil
    end
  end

  defp get_secret_key_base do
    MoomooMarketsWeb.Endpoint.config(:secret_key_base)
  end
end
