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
end
