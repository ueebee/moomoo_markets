defmodule MoomooMarkets.DataSources.JQuants.Error do
  @moduledoc """
  J-Quants APIのエラー定義
  """

  defexception [:message, :code]

  @type t :: %__MODULE__{
    message: String.t(),
    code: String.t()
  }

  @doc """
  エラーメッセージを生成します
  """
  def message(%__MODULE__{message: message, code: code}) do
    "J-Quants API Error: #{message} (Code: #{code})"
  end
end
