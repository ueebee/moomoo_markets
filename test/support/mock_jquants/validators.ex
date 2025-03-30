defmodule MockJQuants.Validators do
  @moduledoc """
  Common validation functions for the J-Quants API mock server.
  """

  @doc """
  Validates date format (YYYYMMDD or YYYY-MM-DD).
  """
  def validate_date_format(date) do
    cond do
      Regex.match?(~r/^\d{8}$/, date) -> {:ok, date}
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date) -> {:ok, date}
      true -> {:error, "Invalid date format. Use YYYYMMDD or YYYY-MM-DD format."}
    end
  end

  @doc """
  Validates stock code format (4 or 5 digits).
  """
  def validate_stock_code(code) do
    cond do
      Regex.match?(~r/^\d{4,5}$/, code) -> {:ok, code}
      true -> {:error, "Invalid stock code format. Use 4 or 5 digits."}
    end
  end

  @doc """
  Parses date string into Date struct.
  """
  def parse_date(date_str) do
    case date_str do
      <<year::binary-4, month::binary-2, day::binary-2>> ->
        Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))
      date_str when is_binary(date_str) ->
        case String.split(date_str, "-") do
          [year, month, day] ->
            Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))
          _ ->
            {:error, :invalid_format}
        end
      _ ->
        {:error, :invalid_format}
    end
  end
end
