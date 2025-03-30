defmodule MockJQuants.Server do
  @moduledoc """
  Mock server for J-Quants API
  """
  use Plug.Router
  require Logger
  alias MockJQuants.Responses.{Error, Success}
  alias MockJQuants.Handlers.{AuthHandler, ListedInfoHandler, DailyQuotesHandler}

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

  # ルートの定義
  get "/" do
    Success.generate(conn, 200, %{"message" => "Hello from MockJQuants.Server!"})
  end

  post "/token/auth_user", do: AuthHandler.handle_auth_user(conn)
  post "/token/auth_refresh", do: AuthHandler.handle_auth_refresh(conn)
  get "/listed/info", do: ListedInfoHandler.handle_request(conn)
  get "/prices/daily_quotes", do: DailyQuotesHandler.handle_request(conn)

  # デフォルトのルート
  match _ do
    Error.not_found(conn)
  end
end
