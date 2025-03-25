defmodule MoomooMarkets.DataSources.JQuants.Types do
  @moduledoc """
  J-Quants APIの型定義
  """

  @type t :: %__MODULE__{
    refresh_token: String.t(),
    refresh_token_expired_at: DateTime.t(),
    id_token: String.t() | nil,
    id_token_expired_at: DateTime.t() | nil
  }

  defstruct [:refresh_token, :refresh_token_expired_at, :id_token, :id_token_expired_at]

  @type credentials :: %{
    mailaddress: String.t(),
    password: String.t()
  }

  @type token_response :: %{
    refreshToken: String.t()
  }

  @type id_token_response :: %{
    idToken: String.t(),
    refreshToken: String.t()
  }

  @type listed_info :: %{
    code: String.t(),
    name: String.t(),
    sector_code: String.t() | nil,
    sector_name: String.t() | nil,
    market_code: String.t() | nil,
    market_name: String.t() | nil,
    effective_date: Date.t()
  }

  @type listed_info_response :: %{
    listed_info: [listed_info()]
  }

  @type api_response :: {:ok, listed_info_response()} | {:error, String.t()}
end
