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
                    Success.generate(conn, 200, data)
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

  defp generate_mock_data(%{"code" => "7203", "from" => _from, "to" => _to}) do
    {:ok, %{
      "daily_quotes" => [
        %{
          "Code" => "7203",
          "Date" => "2024-03-24",
          "Open" => 3500,
          "High" => 3550,
          "Low" => 3480,
          "Close" => 3520,
          "UpperLimit" => 3800,
          "LowerLimit" => 3200,
          "Volume" => 1000000,
          "TurnoverValue" => 3500000000
        },
        %{
          "Code" => "7203",
          "Date" => "2024-03-25",
          "Open" => 3520,
          "High" => 3580,
          "Low" => 3500,
          "Close" => 3550,
          "UpperLimit" => 3800,
          "LowerLimit" => 3200,
          "Volume" => 1200000,
          "TurnoverValue" => 4200000000
        }
      ]
    }}
  end

  defp generate_mock_data(_params) do
    {:error, :internal_server_error}
  end
end
