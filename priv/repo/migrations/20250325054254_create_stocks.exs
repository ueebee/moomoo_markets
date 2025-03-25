defmodule MoomooMarkets.Repo.Migrations.CreateStocks do
  use Ecto.Migration

  def change do
    create table(:stocks) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :name_en, :string
      add :sector_code, :string
      add :sector_name, :string
      add :sub_sector_code, :string
      add :sub_sector_name, :string
      add :scale_category, :string
      add :market_code, :string
      add :market_name, :string
      add :margin_code, :string
      add :margin_name, :string
      add :effective_date, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stocks, [:code])
    create index(:stocks, [:effective_date])
    create unique_index(:stocks, [:code, :effective_date])
  end
end
