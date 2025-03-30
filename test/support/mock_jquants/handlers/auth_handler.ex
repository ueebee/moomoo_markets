defmodule MockJQuants.Handlers.AuthHandler do
  @moduledoc """
  Handler for authentication-related endpoints.
  """
  alias MockJQuants.Responses.{Error, Success}

  @doc """
  Handles the /token/auth_user endpoint.
  """
  def handle_auth_user(conn) do
    try do
      case conn.body_params do
        %{"mailaddress" => mail, "password" => password} ->
          if mail == "test@example.com" and password == "test_password" do
            Success.generate(conn, 200, %{"refreshToken" => "new_refresh_token"})
          else
            if mail == "forbidden@example.com" do
              Error.forbidden(conn, "Missing Authentication Token. The method or resources may not be supported.")
            else
              Error.bad_request(conn, "mailaddress or password is incorrect.")
            end
          end
        _ ->
          Error.bad_request(conn, "Missing required parameters")
      end
    catch
      _ ->
        Error.internal_server_error(conn)
    end
  end

  @doc """
  Handles the /token/auth_refresh endpoint.
  """
  def handle_auth_refresh(conn) do
    try do
      case conn.query_params do
        %{"refreshtoken" => refresh_token} ->
          if refresh_token == "new_refresh_token" do
            Success.generate(conn, 200, %{"idToken" => "new_id_token"})
          else
            if refresh_token == "forbidden_token" do
              Error.forbidden(conn, "Missing Authentication Token. The method or resources may not be supported.")
            else
              Error.bad_request(conn, "refreshtoken is incorrect.")
            end
          end
        _ ->
          Error.bad_request(conn, "refreshtoken is required.")
      end
    catch
      _ ->
        Error.internal_server_error(conn)
    end
  end
end
