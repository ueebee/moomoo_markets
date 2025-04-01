defmodule MockJQuants.Handlers.TradesSpecHandler do
  @moduledoc """
  Handler for trades spec endpoint (/markets/trades_spec)
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
      is_nil(params["section"]) ->
        {:error, "section parameter is required"}

      is_nil(params["from"]) ->
        {:error, "from parameter is required"}

      is_nil(params["to"]) ->
        {:error, "to parameter is required"}

      not valid_section?(params["section"]) ->
        {:error, "Invalid market section"}

      not valid_date_range?(params["from"], params["to"]) ->
        {:error, "Invalid date range"}

      true ->
        {:ok, params}
    end
  end

  defp valid_section?(section) do
    section in [
      "TSEPrime",
      "TSEStandard",
      "TSEContinuous",
      "TSE1st",
      "TSE2nd",
      "TSEJASDAQ",
      "TSEJASDAQStandard",
      "TSEJASDAQGrowth"
    ]
  end

  defp valid_date_range?(from, to) do
    case {Date.from_iso8601(from), Date.from_iso8601(to)} do
      {{:ok, from_date}, {:ok, to_date}} ->
        Date.compare(from_date, to_date) != :gt
      _ ->
        false
    end
  end

  defp generate_mock_data(%{"section" => section, "from" => from, "to" => to}) do
    {:ok, %{
      "trades_spec" => [
        %{
          "PublishedDate" => from,
          "StartDate" => from,
          "EndDate" => to,
          "Section" => section,
          "ProprietarySales" => 1311271004.0,
          "ProprietaryPurchases" => 1453326508.0,
          "ProprietaryTotal" => 2764597512.0,
          "ProprietaryBalance" => 142055504.0,
          "BrokerageSales" => 7165529005.0,
          "BrokeragePurchases" => 7030019854.0,
          "BrokerageTotal" => 14195548859.0,
          "BrokerageBalance" => -135509151.0,
          "TotalSales" => 8476800009.0,
          "TotalPurchases" => 8483346362.0,
          "TotalTotal" => 16960146371.0,
          "TotalBalance" => 6546353.0,
          "IndividualsSales" => 1401711615.0,
          "IndividualsPurchases" => 1161801155.0,
          "IndividualsTotal" => 2563512770.0,
          "IndividualsBalance" => -239910460.0,
          "ForeignersSales" => 5094891735.0,
          "ForeignersPurchases" => 5317151774.0,
          "ForeignersTotal" => 10412043509.0,
          "ForeignersBalance" => 222260039.0,
          "SecuritiesCosSales" => 76381455.0,
          "SecuritiesCosPurchases" => 61700100.0,
          "SecuritiesCosTotal" => 138081555.0,
          "SecuritiesCosBalance" => -14681355.0,
          "InvestmentTrustsSales" => 168705109.0,
          "InvestmentTrustsPurchases" => 124389642.0,
          "InvestmentTrustsTotal" => 293094751.0,
          "InvestmentTrustsBalance" => -44315467.0,
          "BusinessCosSales" => 71217959.0,
          "BusinessCosPurchases" => 63526641.0,
          "BusinessCosTotal" => 134744600.0,
          "BusinessCosBalance" => -7691318.0,
          "OtherCosSales" => 10745152.0,
          "OtherCosPurchases" => 15687836.0,
          "OtherCosTotal" => 26432988.0,
          "OtherCosBalance" => 4942684.0,
          "InsuranceCosSales" => 15926202.0,
          "InsuranceCosPurchases" => 9831555.0,
          "InsuranceCosTotal" => 25757757.0,
          "InsuranceCosBalance" => -6094647.0,
          "CityBKsRegionalBKsEtcSales" => 10606789.0,
          "CityBKsRegionalBKsEtcPurchases" => 8843871.0,
          "CityBKsRegionalBKsEtcTotal" => 19450660.0,
          "CityBKsRegionalBKsEtcBalance" => -1762918.0,
          "TrustBanksSales" => 292932297.0,
          "TrustBanksPurchases" => 245322795.0,
          "TrustBanksTotal" => 538255092.0,
          "TrustBanksBalance" => -47609502.0,
          "OtherFinancialInstitutionsSales" => 22410692.0,
          "OtherFinancialInstitutionsPurchases" => 21764485.0,
          "OtherFinancialInstitutionsTotal" => 44175177.0,
          "OtherFinancialInstitutionsBalance" => -646207.0
        }
      ]
    }}
  end

  defp generate_mock_data(_params) do
    {:error, :internal_server_error}
  end
end
