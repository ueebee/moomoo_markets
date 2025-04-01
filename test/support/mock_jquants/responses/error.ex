defmodule MockJQuants.Responses.Error do
  @moduledoc """
  Common error response generator for the J-Quants API mock server.
  """
  import Plug.Conn

  @doc """
  Generates a JSON error response with the given status code and message.
  """
  def generate(conn, status_code, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(%{"message" => message}))
  end

  @doc """
  Generates a 400 Bad Request error response.
  """
  def bad_request(conn, message) do
    generate(conn, 400, message)
  end

  @doc """
  Generates a 401 Unauthorized error response.
  """
  def unauthorized(conn, message) do
    generate(conn, 401, message)
  end

  @doc """
  Generates a 403 Forbidden error response.
  """
  def forbidden(conn, message) do
    generate(conn, 403, message)
  end

  @doc """
  Generates a 404 Not Found error response.
  """
  def not_found(conn) do
    generate(conn, 404, "Not found")
  end

  @doc """
  Generates a 500 Internal Server Error response.
  """
  def internal_server_error(conn) do
    generate(conn, 500, "Unexpected error. Please try again later.")
  end
end
