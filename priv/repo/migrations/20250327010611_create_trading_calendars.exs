defmodule MoomooMarkets.Repo.Migrations.CreateTradingCalendars do
  use Ecto.Migration

  def change do
    create table(:trading_calendars) do
      add :date, :date, null: false, comment: "日付"
      add :holiday_division, :string, null: false, comment: "休日区分"

      timestamps()
    end

    create unique_index(:trading_calendars, [:date])
    create index(:trading_calendars, [:holiday_division])
  end
end
