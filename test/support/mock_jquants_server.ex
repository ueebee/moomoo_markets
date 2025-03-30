# test/support/mock_jquants_server.ex
defmodule MockJQuantsServer do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

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

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{"message" => "Not Found"}))
  end
end
