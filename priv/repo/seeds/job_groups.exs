alias MoomooMarkets.{Repo, Jobs.JobGroup, DataSources.DataSource}

# J-Quantsのデータソースを取得
jquants = Repo.get_by(DataSource, provider_type: "jquants")

# 上場企業情報用のジョブグループ
Repo.insert!(%JobGroup{
  name: "上場企業情報",
  description: "J-Quantsから上場企業情報を取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Stock",
  data_source_id: jquants.id,
  schedule: "0 0 * * 1",  # 毎週月曜0時に実行
  parameters_template: %{},  # パラメータ不要
  is_enabled: false
})

# 売買内訳データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "売買内訳データ",
  description: "J-Quantsから売買内訳データを取得（東証上場銘柄の東証市場における銘柄別の日次売買代金・売買高）",
  schema_module: "MoomooMarkets.DataSources.JQuants.Breakdown",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "code" => "7203",  # トヨタ自動車をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 株価データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "株価データ",
  description: "J-Quantsから株価データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.StockPrice",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "code" => "7203",  # トヨタ自動車をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 財務諸表データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "財務諸表データ",
  description: "J-Quantsから財務諸表データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Statement",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "code" => "7203",  # トヨタ自動車をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 株価指数データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "株価指数データ",
  description: "J-Quantsから株価指数データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.Index",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "code" => "0000",  # 日経平均株価をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 空売り比率データ用のジョブグループ
Repo.insert!(%JobGroup{
  name: "空売り比率データ",
  description: "J-Quantsから空売り比率データを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.ShortSelling",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "code" => "7203",  # トヨタ自動車をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 投資部門別売買状況用のジョブグループ
Repo.insert!(%JobGroup{
  name: "投資部門別売買状況",
  description: "J-Quantsから投資部門別売買状況を取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.TradesSpec",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "section" => "TSE",  # 東証をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 取引カレンダー用のジョブグループ
Repo.insert!(%JobGroup{
  name: "取引カレンダー",
  description: "J-Quantsから取引カレンダーを取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.TradingCalendar",
  data_source_id: jquants.id,
  schedule: "0 0 * * *",  # 毎日0時に実行
  parameters_template: %{
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})

# 週間信用取引残高用のジョブグループ
Repo.insert!(%JobGroup{
  name: "週間信用取引残高",
  description: "J-Quantsから週間信用取引残高を取得",
  schema_module: "MoomooMarkets.DataSources.JQuants.WeeklyMarginInterest",
  data_source_id: jquants.id,
  schedule: "0 0 * * 1",  # 毎週月曜0時に実行
  parameters_template: %{
    "code" => "7203",  # トヨタ自動車をデフォルトとして設定
    "from_date" => "2024-01-01",
    "to_date" => "2024-01-31"
  },
  is_enabled: false
})
