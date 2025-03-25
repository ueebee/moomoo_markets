defmodule MoomooMarkets.DataSources.JQuants.Error do
  @moduledoc """
  J-Quants APIのエラー定義
  """

  @type t :: %__MODULE__{
    code: atom(),
    message: String.t(),
    details: map() | nil
  }

  defexception [:code, :message, :details]

  @doc """
  エラーメッセージを生成します
  """
  def message(%__MODULE__{message: message, code: code}) do
    "J-Quants API Error: #{message} (Code: #{code})"
  end

  def error(code, message, details \\ nil) do
    %__MODULE__{code: code, message: message, details: details}
  end
end
