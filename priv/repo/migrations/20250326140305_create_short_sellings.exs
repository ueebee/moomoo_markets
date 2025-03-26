defmodule MoomooMarkets.Repo.Migrations.CreateShortSellings do
  use Ecto.Migration

  def change do
    create table(:short_sellings) do
      add :date, :date, null: false, comment: "日付"
      add :sector33_code, :string, null: false, comment: "33業種コード"
      add :selling_excluding_short_selling_turnover_value, :float, null: false, comment: "実注文の売買代金"
      add :short_selling_with_restrictions_turnover_value, :float, null: false, comment: "価格規制有りの空売り売買代金"
      add :short_selling_without_restrictions_turnover_value, :float, null: false, comment: "価格規制無しの空売り売買代金"

      timestamps()
    end

    # 複合ユニーク制約
    create unique_index(:short_sellings, [:date, :sector33_code])

    # 個別のインデックス
    create index(:short_sellings, [:date])
    create index(:short_sellings, [:sector33_code])
  end
end
