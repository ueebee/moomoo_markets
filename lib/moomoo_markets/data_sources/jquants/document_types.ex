defmodule MoomooMarkets.DataSources.JQuants.DocumentTypes do
  @moduledoc """
  開示書類種別を定数として管理するモジュール。
  J-Quants APIの財務情報データで使用される開示書類種別を定義します。
  """

  @type document_type :: String.t()

  @doc """
  開示書類種別の一覧を返します。
  """
  @spec all_types() :: [document_type()]
  def all_types do
    [
      # 決算短信（連結・日本基準）
      "FYFinancialStatements_Consolidated_JP",
      "1QFinancialStatements_Consolidated_JP",
      "2QFinancialStatements_Consolidated_JP",
      "3QFinancialStatements_Consolidated_JP",
      "OtherPeriodFinancialStatements_Consolidated_JP",

      # 決算短信（連結・米国基準）
      "FYFinancialStatements_Consolidated_US",
      "1QFinancialStatements_Consolidated_US",
      "2QFinancialStatements_Consolidated_US",
      "3QFinancialStatements_Consolidated_US",
      "OtherPeriodFinancialStatements_Consolidated_US",

      # 決算短信（非連結・日本基準）
      "FYFinancialStatements_NonConsolidated_JP",
      "1QFinancialStatements_NonConsolidated_JP",
      "2QFinancialStatements_NonConsolidated_JP",
      "3QFinancialStatements_NonConsolidated_JP",
      "OtherPeriodFinancialStatements_NonConsolidated_JP",

      # 決算短信（連結・ＪＭＩＳ）
      "FYFinancialStatements_Consolidated_JMIS",
      "1QFinancialStatements_Consolidated_JMIS",
      "2QFinancialStatements_Consolidated_JMIS",
      "3QFinancialStatements_Consolidated_JMIS",
      "OtherPeriodFinancialStatements_Consolidated_JMIS",

      # 決算短信（非連結・ＩＦＲＳ）
      "FYFinancialStatements_NonConsolidated_IFRS",
      "1QFinancialStatements_NonConsolidated_IFRS",
      "2QFinancialStatements_NonConsolidated_IFRS",
      "3QFinancialStatements_NonConsolidated_IFRS",
      "OtherPeriodFinancialStatements_NonConsolidated_IFRS",

      # 決算短信（連結・ＩＦＲＳ）
      "FYFinancialStatements_Consolidated_IFRS",
      "1QFinancialStatements_Consolidated_IFRS",
      "2QFinancialStatements_Consolidated_IFRS",
      "3QFinancialStatements_Consolidated_IFRS",
      "OtherPeriodFinancialStatements_Consolidated_IFRS",

      # 決算短信（非連結・外国株）
      "FYFinancialStatements_NonConsolidated_Foreign",
      "1QFinancialStatements_NonConsolidated_Foreign",
      "2QFinancialStatements_NonConsolidated_Foreign",
      "3QFinancialStatements_NonConsolidated_Foreign",
      "OtherPeriodFinancialStatements_NonConsolidated_Foreign",

      # 決算短信（連結・外国株）
      "FYFinancialStatements_Consolidated_Foreign",
      "1QFinancialStatements_Consolidated_Foreign",
      "2QFinancialStatements_Consolidated_Foreign",
      "3QFinancialStatements_Consolidated_Foreign",
      "OtherPeriodFinancialStatements_Consolidated_Foreign",

      # 決算短信（REIT）
      "FYFinancialStatements_Consolidated_REIT",

      # 予想修正
      "DividendForecastRevision",
      "EarnForecastRevision",
      "REITDividendForecastRevision",
      "REITEarnForecastRevision"
    ]
  end

  @doc """
  開示書類種別に対応する説明を返します。
  """
  @spec get_description(document_type()) :: String.t()
  def get_description(type) do
    case type do
      # 決算短信（連結・日本基準）
      "FYFinancialStatements_Consolidated_JP" -> "決算短信（連結・日本基準）"
      "1QFinancialStatements_Consolidated_JP" -> "第1四半期決算短信（連結・日本基準）"
      "2QFinancialStatements_Consolidated_JP" -> "第2四半期決算短信（連結・日本基準）"
      "3QFinancialStatements_Consolidated_JP" -> "第3四半期決算短信（連結・日本基準）"
      "OtherPeriodFinancialStatements_Consolidated_JP" -> "その他四半期決算短信（連結・日本基準）"

      # 決算短信（連結・米国基準）
      "FYFinancialStatements_Consolidated_US" -> "決算短信（連結・米国基準）"
      "1QFinancialStatements_Consolidated_US" -> "第1四半期決算短信（連結・米国基準）"
      "2QFinancialStatements_Consolidated_US" -> "第2四半期決算短信（連結・米国基準）"
      "3QFinancialStatements_Consolidated_US" -> "第3四半期決算短信（連結・米国基準）"
      "OtherPeriodFinancialStatements_Consolidated_US" -> "その他四半期決算短信（連結・米国基準）"

      # 決算短信（非連結・日本基準）
      "FYFinancialStatements_NonConsolidated_JP" -> "決算短信（非連結・日本基準）"
      "1QFinancialStatements_NonConsolidated_JP" -> "第1四半期決算短信（非連結・日本基準）"
      "2QFinancialStatements_NonConsolidated_JP" -> "第2四半期決算短信（非連結・日本基準）"
      "3QFinancialStatements_NonConsolidated_JP" -> "第3四半期決算短信（非連結・日本基準）"
      "OtherPeriodFinancialStatements_NonConsolidated_JP" -> "その他四半期決算短信（非連結・日本基準）"

      # 決算短信（連結・ＪＭＩＳ）
      "FYFinancialStatements_Consolidated_JMIS" -> "決算短信（連結・ＪＭＩＳ）"
      "1QFinancialStatements_Consolidated_JMIS" -> "第1四半期決算短信（連結・ＪＭＩＳ）"
      "2QFinancialStatements_Consolidated_JMIS" -> "第2四半期決算短信（連結・ＪＭＩＳ）"
      "3QFinancialStatements_Consolidated_JMIS" -> "第3四半期決算短信（連結・ＪＭＩＳ）"
      "OtherPeriodFinancialStatements_Consolidated_JMIS" -> "その他四半期決算短信（連結・ＪＭＩＳ）"

      # 決算短信（非連結・ＩＦＲＳ）
      "FYFinancialStatements_NonConsolidated_IFRS" -> "決算短信（非連結・ＩＦＲＳ）"
      "1QFinancialStatements_NonConsolidated_IFRS" -> "第1四半期決算短信（非連結・ＩＦＲＳ）"
      "2QFinancialStatements_NonConsolidated_IFRS" -> "第2四半期決算短信（非連結・ＩＦＲＳ）"
      "3QFinancialStatements_NonConsolidated_IFRS" -> "第3四半期決算短信（非連結・ＩＦＲＳ）"
      "OtherPeriodFinancialStatements_NonConsolidated_IFRS" -> "その他四半期決算短信（非連結・ＩＦＲＳ）"

      # 決算短信（連結・ＩＦＲＳ）
      "FYFinancialStatements_Consolidated_IFRS" -> "決算短信（連結・ＩＦＲＳ）"
      "1QFinancialStatements_Consolidated_IFRS" -> "第1四半期決算短信（連結・ＩＦＲＳ）"
      "2QFinancialStatements_Consolidated_IFRS" -> "第2四半期決算短信（連結・ＩＦＲＳ）"
      "3QFinancialStatements_Consolidated_IFRS" -> "第3四半期決算短信（連結・ＩＦＲＳ）"
      "OtherPeriodFinancialStatements_Consolidated_IFRS" -> "その他四半期決算短信（連結・ＩＦＲＳ）"

      # 決算短信（非連結・外国株）
      "FYFinancialStatements_NonConsolidated_Foreign" -> "決算短信（非連結・外国株）"
      "1QFinancialStatements_NonConsolidated_Foreign" -> "第1四半期決算短信（非連結・外国株）"
      "2QFinancialStatements_NonConsolidated_Foreign" -> "第2四半期決算短信（非連結・外国株）"
      "3QFinancialStatements_NonConsolidated_Foreign" -> "第3四半期決算短信（非連結・外国株）"
      "OtherPeriodFinancialStatements_NonConsolidated_Foreign" -> "その他四半期決算短信（非連結・外国株）"

      # 決算短信（連結・外国株）
      "FYFinancialStatements_Consolidated_Foreign" -> "決算短信（連結・外国株）"
      "1QFinancialStatements_Consolidated_Foreign" -> "第1四半期決算短信（連結・外国株）"
      "2QFinancialStatements_Consolidated_Foreign" -> "第2四半期決算短信（連結・外国株）"
      "3QFinancialStatements_Consolidated_Foreign" -> "第3四半期決算短信（連結・外国株）"
      "OtherPeriodFinancialStatements_Consolidated_Foreign" -> "その他四半期決算短信（連結・外国株）"

      # 決算短信（REIT）
      "FYFinancialStatements_Consolidated_REIT" -> "決算短信（REIT）"

      # 予想修正
      "DividendForecastRevision" -> "配当予想の修正"
      "EarnForecastRevision" -> "業績予想の修正"
      "REITDividendForecastRevision" -> "分配予想の修正"
      "REITEarnForecastRevision" -> "利益予想の修正"

      _ -> raise ArgumentError, "Invalid document type: #{type}"
    end
  end

  @doc """
  開示書類種別が有効かどうかを確認します。
  """
  @spec valid_type?(document_type()) :: boolean()
  def valid_type?(type) do
    type in all_types()
  end
end
