defmodule MockJQuants.Handlers.DailyQuotesHandler do
  @moduledoc """
  Handler for daily quotes endpoint (/prices/daily_quotes)
  """
  alias MockJQuants.Responses.{Error, Success}

  def handle_request(conn) do
    try do
      # 認証ヘッダーの確認
      case Enum.find(conn.req_headers, fn {name, _} -> name == "authorization" end) do
        {"authorization", "Bearer " <> token} ->
          if token == "new_id_token" do
            # パラメータの検証
            case validate_params(conn.query_params) do
              {:ok, params} ->
                case generate_mock_data(params) do
                  {:ok, data} ->
                    Success.generate(conn, 200, %{daily_quotes: data})
                  {:error, :internal_server_error} ->
                    Error.internal_server_error(conn)
                end
              {:error, message} ->
                Error.bad_request(conn, message)
            end
          else
            Error.unauthorized(conn, "The incoming token is invalid or expired.")
          end
        _ ->
          Error.unauthorized(conn, "Missing Authorization header.")
      end
    catch
      _ ->
        Error.internal_server_error(conn)
    end
  end

  defp validate_params(params) do
    cond do
      is_nil(params["code"]) ->
        {:error, "code parameter is required"}

      is_nil(params["from"]) ->
        {:error, "from parameter is required"}

      is_nil(params["to"]) ->
        {:error, "to parameter is required"}

      true ->
        {:ok, params}
    end
  end

  defp generate_mock_data(%{"code" => "7203", "from" => from, "to" => to}) do
    # トヨタ自動車のモックデータ
    mock_data = [
      %{
        "Date" => "2024-03-24",
        "Code" => "7203",
        "Open" => 3500.0,
        "High" => 3550.0,
        "Low" => 3480.0,
        "Close" => 3520.0,
        "UpperLimit" => "0",
        "LowerLimit" => "0",
        "Volume" => 12_500_000.0,
        "TurnoverValue" => 44_000_000_000.0,
        "AdjustmentFactor" => 1.0,
        "AdjustmentOpen" => 3500.0,
        "AdjustmentHigh" => 3550.0,
        "AdjustmentLow" => 3480.0,
        "AdjustmentClose" => 3520.0,
        "AdjustmentVolume" => 12_500_000.0
      },
      %{
        "Date" => "2024-03-25",
        "Code" => "7203",
        "Open" => 3520.0,
        "High" => 3580.0,
        "Low" => 3510.0,
        "Close" => 3550.0,
        "UpperLimit" => "0",
        "LowerLimit" => "0",
        "Volume" => 13_000_000.0,
        "TurnoverValue" => 46_150_000_000.0,
        "AdjustmentFactor" => 1.0,
        "AdjustmentOpen" => 3520.0,
        "AdjustmentHigh" => 3580.0,
        "AdjustmentLow" => 3510.0,
        "AdjustmentClose" => 3550.0,
        "AdjustmentVolume" => 13_000_000.0
      }
    ]

    {:ok, mock_data}
  end

  defp generate_mock_data(_params) do
    {:error, :internal_server_error}
  end
end
