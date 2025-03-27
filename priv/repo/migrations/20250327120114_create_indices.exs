defmodule MoomooMarkets.Repo.Migrations.CreateIndices do
  use Ecto.Migration

  def change do
    create table(:indices) do
      add :date, :date, null: false, comment: "日付"
      add :code, :string, null: false, comment: "指数コード"
      add :open, :float, null: false, comment: "始値"
      add :high, :float, null: false, comment: "高値"
      add :low, :float, null: false, comment: "安値"
      add :close, :float, null: false, comment: "終値"

      timestamps()
    end

    create unique_index(:indices, [:date, :code])
    create index(:indices, [:code])
  end
end
