# test/support/mock_jquants_server.ex
defmodule MockJQuantsServer do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

  # 日付形式のバリデーション
  defp validate_date_format(date) do
    # YYYYMMDD or YYYY-MM-DD 形式をチェック
    cond do
      Regex.match?(~r/^\d{8}$/, date) -> {:ok, date}
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date) -> {:ok, date}
      true -> {:error, "Invalid date format. Use YYYYMMDD or YYYY-MM-DD format."}
    end
  end

  # 銘柄コードのバリデーション
  defp validate_stock_code(code) do
    # 4桁または5桁の数字をチェック
    cond do
      Regex.match?(~r/^\d{4,5}$/, code) -> {:ok, code}
      true -> {:error, "Invalid stock code format. Use 4 or 5 digits."}
    end
  end

  # 日付範囲のバリデーション
  defp validate_date_range(from, to) do
    with {:ok, from_date} <- parse_date(from),
         {:ok, to_date} <- parse_date(to) do
      if Date.compare(from_date, to_date) == :gt do
        {:error, "Invalid date range. 'from' date must be before or equal to 'to' date."}
      else
        {:ok, {from, to}}
      end
    else
      _ -> {:error, "Invalid date format in range parameters."}
    end
  end

  # 日付文字列をDate型に変換
  defp parse_date(date_str) do
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

  # 10年以上前のデータかどうかをチェック
  defp is_historical_data?(date_str) do
    with {:ok, date} <- parse_date(date_str) do
      today = Date.utc_today()
      Date.diff(today, date) > 3650  # 10年 = 3650日
    else
      _ -> false
    end
  end

  post "/token/auth_user" do
    try do
      case conn.body_params do
        %{"mailaddress" => mail, "password" => password} ->
          if mail == "test@example.com" and password == "test_password" do
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{"refreshToken" => "new_refresh_token"}))
          else
            if mail == "forbidden@example.com" do
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(403, Jason.encode!(%{"message" => "Missing Authentication Token. The method or resources may not be supported."}))
            else
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(400, Jason.encode!(%{"message" => "'mailaddress' or 'password' is incorrect."}))
            end
          end
        _ ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{"message" => "Missing required parameters"}))
      end
    catch
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{"message" => "Unexpected error. Please try again later."}))
    end
  end

  post "/token/auth_refresh" do
    try do
      # IO.puts "\n=== Mock Server Debug ==="
      # IO.puts "Received request to /token/auth_refresh"
      # IO.puts "Query params: #{inspect(conn.query_params)}"

      result = case conn.query_params do
        %{"refreshtoken" => refresh_token} ->
          IO.puts "Refresh token: #{refresh_token}"
          if refresh_token == "new_refresh_token" do
            IO.puts "Sending success response"
            response = Jason.encode!(%{"idToken" => "new_id_token"})
            IO.puts "Response body: #{response}"
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, response)
          else
            if refresh_token == "forbidden_token" do
              IO.puts "Sending 403 response"
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(403, Jason.encode!(%{"message" => "Missing Authentication Token. The method or resources may not be supported."}))
            else
              IO.puts "Sending 400 response"
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(400, Jason.encode!(%{"message" => "'refreshtoken' is incorrect."}))
            end
          end
        _ ->
          IO.puts "Missing refreshtoken parameter"
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{"message" => "'refreshtoken' is required."}))
      end

      IO.puts "=====================\n"
      result
    catch
      _ ->
        IO.puts "Error in mock server"
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{"message" => "Unexpected error. Please try again later."}))
    end
  end

  get "/prices/daily_quotes" do
    try do
      IO.puts "\n=== Mock Server Debug ==="
      IO.puts "Received request to /prices/daily_quotes"
      IO.puts "Query params: #{inspect(conn.query_params)}"

      # 認証ヘッダーの確認
      case get_req_header(conn, "authorization") do
        ["Bearer " <> token] ->
          if token == "new_id_token" do
            # パラメータの検証
            case conn.query_params do
              %{"code" => code, "from" => from, "to" => to} ->
                # 銘柄コードと日付範囲のバリデーション
                with {:ok, _valid_code} <- validate_stock_code(code),
                     {:ok, _valid_range} <- validate_date_range(from, to) do
                  # 10年以上前のデータへのアクセスをチェック
                  if is_historical_data?(from) or is_historical_data?(to) do
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(403, Jason.encode!(%{"message" => "Access to historical data more than 10 years old is not allowed."}))
                  else
                    # 日付範囲の日数を計算
                    with {:ok, from_date} <- parse_date(from),
                         {:ok, to_date} <- parse_date(to) do
                      days = Date.diff(to_date, from_date) + 1

                      # 1日の場合は1レコード、2日以上の場合は2レコードを返す
                      quotes = if days == 1 do
                        [
                          %{
                            "Date" => from,
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
                        ]
                      else
                        [
                          %{
                            "Date" => from,
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
                          },
                          %{
                            "Date" => to,
                            "Code" => code,
                            "Open" => 2048.0,
                            "High" => 2070.0,
                            "Low" => 2036.0,
                            "Close" => 2046.0,
                            "UpperLimit" => "0",
                            "LowerLimit" => "0",
                            "Volume" => 2202501.0,
                            "TurnoverValue" => 4507051851.0,
                            "AdjustmentFactor" => 1.0,
                            "AdjustmentOpen" => 2048.0,
                            "AdjustmentHigh" => 2070.0,
                            "AdjustmentLow" => 2036.0,
                            "AdjustmentClose" => 2046.0,
                            "AdjustmentVolume" => 2202501.0
                          }
                        ]
                      end

                      # レスポンスの構築（2日以上の場合はpagination_keyを含める）
                      response = %{
                        "daily_quotes" => quotes
                      }

                      response = if days > 1 do
                        Map.put(response, "pagination_key", "next_page_key")
                      else
                        response
                      end

                      conn
                      |> put_resp_content_type("application/json")
                      |> send_resp(200, Jason.encode!(response))
                    else
                      _ ->
                        conn
                        |> put_resp_content_type("application/json")
                        |> send_resp(400, Jason.encode!(%{"message" => "Invalid date format in range parameters."}))
                    end
                  end
                else
                  {:error, message} ->
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(400, Jason.encode!(%{"message" => message}))
                end

              %{"code" => code, "date" => date} ->
                # 銘柄コードと日付のバリデーション
                with {:ok, _valid_code} <- validate_stock_code(code),
                     {:ok, _valid_date} <- validate_date_format(date) do
                  # 10年以上前のデータへのアクセスをチェック
                  if is_historical_data?(date) do
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(403, Jason.encode!(%{"message" => "Access to historical data more than 10 years old is not allowed."}))
                  else
                    # モックデータの生成（2件のデータを返す）
                    response = %{
                      "daily_quotes" => [
                        %{
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
                        },
                        %{
                          "Date" => date,
                          "Code" => code,
                          "Open" => 2048.0,
                          "High" => 2070.0,
                          "Low" => 2036.0,
                          "Close" => 2046.0,
                          "UpperLimit" => "0",
                          "LowerLimit" => "0",
                          "Volume" => 2202501.0,
                          "TurnoverValue" => 4507051851.0,
                          "AdjustmentFactor" => 1.0,
                          "AdjustmentOpen" => 2048.0,
                          "AdjustmentHigh" => 2070.0,
                          "AdjustmentLow" => 2036.0,
                          "AdjustmentClose" => 2046.0,
                          "AdjustmentVolume" => 2202501.0
                        }
                      ],
                      "pagination_key" => "next_page_key"
                    }

                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(200, Jason.encode!(response))
                  end
                else
                  {:error, message} ->
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(400, Jason.encode!(%{"message" => message}))
                end

              %{"date" => date} ->
                # 日付のバリデーション
                case validate_date_format(date) do
                  {:ok, _valid_date} ->
                    # 10年以上前のデータへのアクセスをチェック
                    if is_historical_data?(date) do
                      conn
                      |> put_resp_content_type("application/json")
                      |> send_resp(403, Jason.encode!(%{"message" => "Access to historical data more than 10 years old is not allowed."}))
                    else
                      # 1件のデータを返す（pagination_keyなし）
                      conn
                      |> put_resp_content_type("application/json")
                      |> send_resp(200, Jason.encode!(%{
                        "daily_quotes" => [
                          %{
                            "Date" => date,
                            "Code" => "86970",
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
                        ]
                      }))
                    end
                  {:error, message} ->
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(400, Jason.encode!(%{"message" => message}))
                end

              %{"code" => code} ->
                # 銘柄コードのバリデーション
                case validate_stock_code(code) do
                  {:ok, _valid_code} ->
                    # 最新の日次株価データを返す
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(200, Jason.encode!(%{
                      "daily_quotes" => [
                        %{
                          "Date" => "20240324",
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
                      ]
                    }))
                  {:error, message} ->
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(400, Jason.encode!(%{"message" => message}))
                end

              %{"from" => from, "to" => to} ->
                # 日付範囲のバリデーション
                case validate_date_range(from, to) do
                  {:ok, _valid_range} ->
                    # 10年以上前のデータへのアクセスをチェック
                    if is_historical_data?(from) or is_historical_data?(to) do
                      conn
                      |> put_resp_content_type("application/json")
                      |> send_resp(403, Jason.encode!(%{"message" => "Access to historical data more than 10 years old is not allowed."}))
                    else
                      conn
                      |> put_resp_content_type("application/json")
                      |> send_resp(200, Jason.encode!(%{
                        "daily_quotes" => [],
                        "pagination_key" => "value1.value2."
                      }))
                    end
                  {:error, message} ->
                    conn
                    |> put_resp_content_type("application/json")
                    |> send_resp(400, Jason.encode!(%{"message" => message}))
                end

              _ ->
                # 必須パラメータが不足している場合
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(400, Jason.encode!(%{"message" => "code, from, and to parameters are required."}))
            end
          else
            # 無効なトークン
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{"message" => "The incoming token is invalid or expired."}))
          end

        _ ->
          # 認証ヘッダーが不足している場合
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401, Jason.encode!(%{"message" => "Missing Authorization header."}))
      end
    catch
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{"message" => "Unexpected error. Please try again later."}))
    end
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{"message" => "Not Found"}))
  end
end
