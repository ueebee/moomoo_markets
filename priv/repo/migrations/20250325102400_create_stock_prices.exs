defmodule MoomooMarkets.Repo.Migrations.CreateStockPrices do
  use Ecto.Migration

  def change do
    create table(:stock_prices) do
      add :code, :string, null: false
      add :date, :date, null: false
      add :open, :float, null: false
      add :high, :float, null: false
      add :low, :float, null: false
      add :close, :float, null: false
      add :volume, :float, null: false
      add :turnover_value, :float, null: false
      add :adjustment_factor, :float, null: false
      add :adjustment_open, :float, null: false
      add :adjustment_high, :float, null: false
      add :adjustment_low, :float, null: false
      add :adjustment_close, :float, null: false
      add :adjustment_volume, :float, null: false

      timestamps()
    end

    create unique_index(:stock_prices, [:code, :date])
    create index(:stock_prices, [:code])
    create index(:stock_prices, [:date])
  end
end
