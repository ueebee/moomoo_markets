defmodule MoomooMarkets.Repo.Migrations.CreateWeeklyMarginInterests do
  use Ecto.Migration

  def change do
    create table(:weekly_margin_interests) do
      # 主要な識別フィールド
      add :code, :string, null: false, comment: "銘柄コード"
      add :date, :date, null: false, comment: "申込日付（通常は金曜日）"
      add :issue_type, :string, null: false, comment: "銘柄区分（1: 信用銘柄, 2: 貸借銘柄, 3: その他）"

      # 売買残高フィールド
      add :short_margin_trade_volume, :float, null: false, comment: "売合計信用取引週末残高"
      add :long_margin_trade_volume, :float, null: false, comment: "買合計信用取引週末残高"

      # 一般信用取引残高
      add :short_negotiable_margin_trade_volume, :float, null: false, comment: "売一般信用取引週末残高"
      add :long_negotiable_margin_trade_volume, :float, null: false, comment: "買一般信用取引週末残高"

      # 制度信用取引残高
      add :short_standardized_margin_trade_volume, :float, null: false, comment: "売制度信用取引週末残高"
      add :long_standardized_margin_trade_volume, :float, null: false, comment: "買制度信用取引週末残高"

      timestamps()
    end

    # インデックス
    create unique_index(:weekly_margin_interests, [:code, :date, :issue_type])
    create index(:weekly_margin_interests, [:date])
    create index(:weekly_margin_interests, [:code])
    create index(:weekly_margin_interests, [:issue_type])
  end
end
