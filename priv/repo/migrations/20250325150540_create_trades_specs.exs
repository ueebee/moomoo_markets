defmodule MoomooMarkets.Repo.Migrations.CreateTradesSpecs do
  use Ecto.Migration

  def change do
    create table(:trades_specs) do
      # 日付関連
      add :published_date, :date, null: false, comment: "公表日"
      add :start_date, :date, null: false, comment: "開始日"
      add :end_date, :date, null: false, comment: "終了日"
      add :section, :string, null: false, comment: "市場区分"

      # 自己計
      add :proprietary_sales, :float, null: false, comment: "自己計売り"
      add :proprietary_purchases, :float, null: false, comment: "自己計買い"
      add :proprietary_total, :float, null: false, comment: "自己計合計"
      add :proprietary_balance, :float, null: false, comment: "自己計残高"

      # 委託計
      add :brokerage_sales, :float, null: false, comment: "委託計売り"
      add :brokerage_purchases, :float, null: false, comment: "委託計買い"
      add :brokerage_total, :float, null: false, comment: "委託計合計"
      add :brokerage_balance, :float, null: false, comment: "委託計残高"

      # 総計
      add :total_sales, :float, null: false, comment: "総計売り"
      add :total_purchases, :float, null: false, comment: "総計買い"
      add :total_total, :float, null: false, comment: "総計合計"
      add :total_balance, :float, null: false, comment: "総計残高"

      # 個人
      add :individuals_sales, :float, null: false, comment: "個人売り"
      add :individuals_purchases, :float, null: false, comment: "個人買い"
      add :individuals_total, :float, null: false, comment: "個人合計"
      add :individuals_balance, :float, null: false, comment: "個人残高"

      # 外国人
      add :foreigners_sales, :float, null: false, comment: "外国人売り"
      add :foreigners_purchases, :float, null: false, comment: "外国人買い"
      add :foreigners_total, :float, null: false, comment: "外国人合計"
      add :foreigners_balance, :float, null: false, comment: "外国人残高"

      # 証券会社
      add :securities_cos_sales, :float, null: false, comment: "証券会社売り"
      add :securities_cos_purchases, :float, null: false, comment: "証券会社買い"
      add :securities_cos_total, :float, null: false, comment: "証券会社合計"
      add :securities_cos_balance, :float, null: false, comment: "証券会社残高"

      # 投資信託
      add :investment_trusts_sales, :float, null: false, comment: "投資信託売り"
      add :investment_trusts_purchases, :float, null: false, comment: "投資信託買い"
      add :investment_trusts_total, :float, null: false, comment: "投資信託合計"
      add :investment_trusts_balance, :float, null: false, comment: "投資信託残高"

      # 事業法人
      add :business_cos_sales, :float, null: false, comment: "事業法人売り"
      add :business_cos_purchases, :float, null: false, comment: "事業法人買い"
      add :business_cos_total, :float, null: false, comment: "事業法人合計"
      add :business_cos_balance, :float, null: false, comment: "事業法人残高"

      # その他法人
      add :other_cos_sales, :float, null: false, comment: "その他法人売り"
      add :other_cos_purchases, :float, null: false, comment: "その他法人買い"
      add :other_cos_total, :float, null: false, comment: "その他法人合計"
      add :other_cos_balance, :float, null: false, comment: "その他法人残高"

      # 生保・損保
      add :insurance_cos_sales, :float, null: false, comment: "生保・損保売り"
      add :insurance_cos_purchases, :float, null: false, comment: "生保・損保買い"
      add :insurance_cos_total, :float, null: false, comment: "生保・損保合計"
      add :insurance_cos_balance, :float, null: false, comment: "生保・損保残高"

      # 都銀・地銀等
      add :city_bks_regional_bks_etc_sales, :float, null: false, comment: "都銀・地銀等売り"
      add :city_bks_regional_bks_etc_purchases, :float, null: false, comment: "都銀・地銀等買い"
      add :city_bks_regional_bks_etc_total, :float, null: false, comment: "都銀・地銀等合計"
      add :city_bks_regional_bks_etc_balance, :float, null: false, comment: "都銀・地銀等残高"

      # 信託銀行
      add :trust_banks_sales, :float, null: false, comment: "信託銀行売り"
      add :trust_banks_purchases, :float, null: false, comment: "信託銀行買い"
      add :trust_banks_total, :float, null: false, comment: "信託銀行合計"
      add :trust_banks_balance, :float, null: false, comment: "信託銀行残高"

      # その他金融機関
      add :other_financial_institutions_sales, :float, null: false, comment: "その他金融機関売り"
      add :other_financial_institutions_purchases, :float, null: false, comment: "その他金融機関買い"
      add :other_financial_institutions_total, :float, null: false, comment: "その他金融機関合計"
      add :other_financial_institutions_balance, :float, null: false, comment: "その他金融機関残高"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:trades_specs, [:published_date, :start_date, :end_date, :section])

    # 個別のインデックス
    create index(:trades_specs, [:published_date])
    create index(:trades_specs, [:start_date])
    create index(:trades_specs, [:end_date])
    create index(:trades_specs, [:section])
  end
end
