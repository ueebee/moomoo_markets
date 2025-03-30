defmodule MockJQuants.Handlers.ListedInfoHandler do
  @moduledoc """
  Handler for listed stock information endpoints.
  """
  alias MockJQuants.Responses.{Error, Success}

  @doc """
  Handles the /listed/info endpoint.

  ## TODO
  - Phase 2: Add support for query parameters (code and date)
  - Phase 2: Implement parameter validation
  - Phase 2: Add more mock data
  - Phase 3: Implement date-based data filtering
  - Phase 3: Handle edge cases (holidays, future dates)
  - Phase 3: Implement data size limits
  """
  def handle_request(conn) do
    try do
      # 認証ヘッダーの確認
      case Enum.find(conn.req_headers, fn {name, _} -> name == "authorization" end) do
        {"authorization", "Bearer " <> token} ->
          if token == "new_id_token" do
            # モックデータの生成（トヨタ自動車、NTT）
            mock_data = %{
              "info" => [
                %{
                  "Date" => "20240324",
                  "Code" => "7203",
                  "CompanyName" => "トヨタ自動車",
                  "CompanyNameEnglish" => "Toyota Motor Corporation",
                  "Sector17Code" => "3",
                  "Sector17CodeName" => "輸送用機器",
                  "Sector33Code" => "3700",
                  "Sector33CodeName" => "自動車・同附属品製造業",
                  "ScaleCategory" => "TOPIX Large70",
                  "MarketCode" => "0111",
                  "MarketCodeName" => "プライム",
                  "MarginCode" => "1",
                  "MarginCodeName" => "信用"
                },
                %{
                  "Date" => "20240324",
                  "Code" => "9432",
                  "CompanyName" => "日本電信電話",
                  "CompanyNameEnglish" => "NIPPON TELEGRAPH AND TELEPHONE CORPORATION",
                  "Sector17Code" => "9",
                  "Sector17CodeName" => "通信",
                  "Sector33Code" => "6200",
                  "Sector33CodeName" => "通信業",
                  "ScaleCategory" => "TOPIX Large70",
                  "MarketCode" => "0111",
                  "MarketCodeName" => "プライム",
                  "MarginCode" => "1",
                  "MarginCodeName" => "信用"
                }
              ]
            }
            Success.generate(conn, 200, mock_data)
          else
            Error.unauthorized(conn, "The incoming token is invalid or expired.")
          end
        _ ->
          # ヘッダーが見つからない場合のデバッグ情報を出力
          IO.inspect(conn.req_headers, label: "Request Headers")
          Error.unauthorized(conn, "Missing Authorization header.")
      end
    catch
      _ ->
        Error.internal_server_error(conn)
    end
  end
end
