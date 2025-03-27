defmodule MoomooMarkets.Repo.Migrations.CreateStatements do
  use Ecto.Migration

  def change do
    create table(:statements) do
      # 基本情報
      add :disclosed_date, :date, null: false, comment: "開示日"
      add :disclosed_time, :string, comment: "開示時刻"
      add :local_code, :string, null: false, comment: "銘柄コード"
      add :disclosure_number, :string, null: false, comment: "開示番号"
      add :type_of_document, :string, null: false, comment: "開示書類種別"
      add :type_of_current_period, :string, null: false, comment: "当期区分"
      add :current_period_start_date, :date, comment: "当期開始日"
      add :current_period_end_date, :date, comment: "当期終了日"
      add :current_fiscal_year_start_date, :date, comment: "当期事業年度開始日"
      add :current_fiscal_year_end_date, :date, comment: "当期事業年度終了日"
      add :next_fiscal_year_start_date, :date, comment: "次期事業年度開始日"
      add :next_fiscal_year_end_date, :date, comment: "次期事業年度終了日"

      # 主要財務指標
      add :net_sales, :decimal, comment: "売上高"
      add :operating_profit, :decimal, comment: "営業利益"
      add :ordinary_profit, :decimal, comment: "経常利益"
      add :profit, :decimal, comment: "当期純利益"
      add :earnings_per_share, :decimal, comment: "一株当たり当期純利益"
      add :diluted_earnings_per_share, :decimal, comment: "希釈後一株当たり当期純利益"
      add :total_assets, :decimal, comment: "総資産"
      add :equity, :decimal, comment: "純資産"
      add :equity_to_asset_ratio, :decimal, comment: "自己資本比率"
      add :book_value_per_share, :decimal, comment: "一株当たり純資産"

      # 予想値
      add :forecast_net_sales, :decimal, comment: "売上高予想"
      add :forecast_operating_profit, :decimal, comment: "営業利益予想"
      add :forecast_ordinary_profit, :decimal, comment: "経常利益予想"
      add :forecast_profit, :decimal, comment: "当期純利益予想"
      add :forecast_earnings_per_share, :decimal, comment: "一株当たり当期純利益予想"

      # 次期予想値
      add :next_year_forecast_net_sales, :decimal, comment: "次期売上高予想"
      add :next_year_forecast_operating_profit, :decimal, comment: "次期営業利益予想"
      add :next_year_forecast_ordinary_profit, :decimal, comment: "次期経常利益予想"
      add :next_year_forecast_profit, :decimal, comment: "次期当期純利益予想"
      add :next_year_forecast_earnings_per_share, :decimal, comment: "次期一株当たり当期純利益予想"

      # 非連結財務指標
      add :non_consolidated_net_sales, :decimal, comment: "売上高（非連結）"
      add :non_consolidated_operating_profit, :decimal, comment: "営業利益（非連結）"
      add :non_consolidated_ordinary_profit, :decimal, comment: "経常利益（非連結）"
      add :non_consolidated_profit, :decimal, comment: "当期純利益（非連結）"
      add :non_consolidated_earnings_per_share, :decimal, comment: "一株当たり当期純利益（非連結）"
      add :non_consolidated_total_assets, :decimal, comment: "総資産（非連結）"
      add :non_consolidated_equity, :decimal, comment: "純資産（非連結）"
      add :non_consolidated_equity_to_asset_ratio, :decimal, comment: "自己資本比率（非連結）"
      add :non_consolidated_book_value_per_share, :decimal, comment: "一株当たり純資産（非連結）"

      # 非連結予想値（期末）
      add :forecast_non_consolidated_net_sales, :decimal, comment: "売上高予想期末（非連結）"
      add :forecast_non_consolidated_operating_profit, :decimal, comment: "営業利益予想期末（非連結）"
      add :forecast_non_consolidated_ordinary_profit, :decimal, comment: "経常利益予想期末（非連結）"
      add :forecast_non_consolidated_profit, :decimal, comment: "当期純利益予想期末（非連結）"
      add :forecast_non_consolidated_earnings_per_share, :decimal, comment: "一株当たり当期純利益予想期末（非連結）"

      # 翌事業年度予想値（非連結）
      add :next_year_forecast_non_consolidated_net_sales, :decimal, comment: "売上高予想翌事業年度期末（非連結）"
      add :next_year_forecast_non_consolidated_operating_profit, :decimal, comment: "営業利益予想翌事業年度期末（非連結）"
      add :next_year_forecast_non_consolidated_ordinary_profit, :decimal, comment: "経常利益予想翌事業年度期末（非連結）"
      add :next_year_forecast_non_consolidated_profit, :decimal, comment: "当期純利益予想翌事業年度期末（非連結）"
      add :next_year_forecast_non_consolidated_earnings_per_share, :decimal, comment: "一株当たり当期純利益予想翌事業年度期末（非連結）"

      # 第2四半期予想値（非連結）
      add :forecast_non_consolidated_net_sales_2nd_quarter, :decimal, comment: "売上高予想第2四半期末（非連結）"
      add :forecast_non_consolidated_operating_profit_2nd_quarter, :decimal, comment: "営業利益予想第2四半期末（非連結）"
      add :forecast_non_consolidated_ordinary_profit_2nd_quarter, :decimal, comment: "経常利益予想第2四半期末（非連結）"
      add :forecast_non_consolidated_profit_2nd_quarter, :decimal, comment: "当期純利益予想第2四半期末（非連結）"
      add :forecast_non_consolidated_earnings_per_share_2nd_quarter, :decimal, comment: "一株当たり当期純利益予想第2四半期末（非連結）"

      # 翌事業年度第2四半期予想値（非連結）
      add :next_year_forecast_non_consolidated_net_sales_2nd_quarter, :decimal, comment: "売上高予想翌事業年度第2四半期末（非連結）"
      add :next_year_forecast_non_consolidated_operating_profit_2nd_quarter, :decimal, comment: "営業利益予想翌事業年度第2四半期末（非連結）"
      add :next_year_forecast_non_consolidated_ordinary_profit_2nd_quarter, :decimal, comment: "経常利益予想翌事業年度第2四半期末（非連結）"
      add :next_year_forecast_non_consolidated_profit_2nd_quarter, :decimal, comment: "当期純利益予想翌事業年度第2四半期末（非連結）"
      add :next_year_forecast_non_consolidated_earnings_per_share_2nd_quarter, :decimal, comment: "一株当たり当期純利益予想翌事業年度第2四半期末（非連結）"

      # 期中の変更に関する項目
      add :material_changes_in_subsidiaries, :string, comment: "期中における重要な子会社の異動"
      add :significant_changes_in_the_scope_of_consolidation, :string, comment: "期中における連結範囲の重要な変更"
      add :changes_based_on_revisions_of_accounting_standard, :string, comment: "会計基準等の改正に伴う会計方針の変更"
      add :changes_other_than_ones_based_on_revisions_of_accounting_standard, :string, comment: "会計基準等の改正に伴う変更以外の会計方針の変更"
      add :changes_in_accounting_estimates, :string, comment: "会計上の見積りの変更"
      add :retrospective_restatement, :string, comment: "修正再表示"

      # 株式数に関する項目
      add :number_of_issued_and_outstanding_shares_at_the_end_of_fiscal_year_including_treasury_stock, :decimal, comment: "期末発行済株式数"
      add :number_of_treasury_stock_at_the_end_of_fiscal_year, :decimal, comment: "期末自己株式数"
      add :average_number_of_shares, :decimal, comment: "期中平均株式数"

      timestamps()
    end

    create unique_index(:statements, [:disclosure_number])
    create index(:statements, [:local_code])
    create index(:statements, [:disclosed_date])
  end
end
