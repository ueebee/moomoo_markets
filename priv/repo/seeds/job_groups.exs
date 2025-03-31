alias MoomooMarkets.{Repo, Jobs.JobGroup, DataSources.DataSource}

# J-Quantsのデータソースを取得
jquants = Repo.get_by(DataSource, provider_type: "jquants")

# 株価データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "株価データ",
  description: "J-Quantsから株価データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
  data_source_id: jquants.id,
  schedule: "0 * * * *",  # 毎時0分に実行
  parameters_template: %{
    "from_date" => "2024-01-01",
    "to_date" => "2024-12-31"
  },
  is_enabled: true
})

# 財務諸表データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "財務諸表データ",
  description: "J-Quantsから財務諸表データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Statement",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "from_date" => "2024-01-01",
    "to_date" => "2024-12-31"
  },
  is_enabled: true
})

# 企業情報用のジョブグループ
Repo.insert!(%JobGroup{
  name: "企業情報",
  description: "J-Quantsから企業情報を取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Company",
  data_source_id: jquants.id,
  schedule: "0 0 * * 1",  # 毎週月曜0時に実行
  parameters_template: %{},  # 企業情報はパラメータ不要
  is_enabled: true
})

# 株価指数用のジョブグループ
Repo.insert!(%JobGroup{
  name: "株価指数",
  description: "J-Quantsから株価指数データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Index",
  data_source_id: jquants.id,
  schedule: "0 * * * *",  # 毎時0分に実行
  parameters_template: %{
    "from_date" => "2024-01-01",
    "to_date" => "2024-12-31"
  },
  is_enabled: true
})

# ニュース用のジョブグループ
Repo.insert!(%JobGroup{
  name: "ニュース",
  description: "J-Quantsからニュースデータを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.News",
  data_source_id: jquants.id,
  schedule: "*/15 * * * *",  # 15分ごとに実行
  parameters_template: %{
    "from_date" => "2024-01-01",
    "to_date" => "2024-12-31"
  },
  is_enabled: true
})
