defmodule MockJQuants.Responses.Success do
  @moduledoc """
  Common success response generator for the J-Quants API mock server.
  """
  import Plug.Conn

  @doc """
  Generates a JSON success response with the given status code and data.
  """
  def generate(conn, status_code, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(data))
  end

  @doc """
  Generates a daily quotes response with pagination.
  """
  def daily_quotes(conn, quotes, pagination_key \\ nil) do
    response = %{"daily_quotes" => quotes}
    response = if pagination_key, do: Map.put(response, "pagination_key", pagination_key), else: response
    generate(conn, 200, response)
  end

  @doc """
  Generates a single day quote response.
  """
  def single_day_quote(conn, date, code) do
    quote = %{
      "Date" => date,
      "Code" => code,
      "Open" => 2047.0,
      "High" => 2069.0,
      "Low" => 2035.0,
      "Close" => 2045.0,
      "UpperLimit" => "0",
      "LowerLimit" => "0",
      "Volume" => 2202500.0,
      "TurnoverValue" => 4507051850.0,
      "AdjustmentFactor" => 1.0,
      "AdjustmentOpen" => 2047.0,
      "AdjustmentHigh" => 2069.0,
      "AdjustmentLow" => 2035.0,
      "AdjustmentClose" => 2045.0,
      "AdjustmentVolume" => 2202500.0
    }
    daily_quotes(conn, [quote])
  end
end
