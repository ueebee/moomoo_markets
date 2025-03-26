defmodule MoomooMarkets.Repo.Migrations.CreateBreakdowns do
  use Ecto.Migration

  def change do
    create table(:breakdowns) do
      add :date, :date, null: false, comment: "売買日"
      add :code, :string, null: false, comment: "銘柄コード"
      add :long_sell_value, :float, null: false, comment: "実売りの約定代金"
      add :short_sell_without_margin_value, :float, null: false, comment: "空売り(信用新規売りを除く)の約定代金"
      add :margin_sell_new_value, :float, null: false, comment: "信用新規売りの約定代金"
      add :margin_sell_close_value, :float, null: false, comment: "信用返済売りの約定代金"
      add :long_buy_value, :float, null: false, comment: "現物買いの約定代金"
      add :margin_buy_new_value, :float, null: false, comment: "信用新規買いの約定代金"
      add :margin_buy_close_value, :float, null: false, comment: "信用返済買いの約定代金"
      add :long_sell_volume, :float, null: false, comment: "実売りの約定株数"
      add :short_sell_without_margin_volume, :float, null: false, comment: "空売り(信用新規売りを除く)の約定株数"
      add :margin_sell_new_volume, :float, null: false, comment: "信用新規売りの約定株数"
      add :margin_sell_close_volume, :float, null: false, comment: "信用返済売りの約定株数"
      add :long_buy_volume, :float, null: false, comment: "現物買いの約定株数"
      add :margin_buy_new_volume, :float, null: false, comment: "信用新規買いの約定株数"
      add :margin_buy_close_volume, :float, null: false, comment: "信用返済買いの約定株数"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:breakdowns, [:date, :code])

    # 個別のインデックス
    create index(:breakdowns, [:date])
    create index(:breakdowns, [:code])
  end
end
