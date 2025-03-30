# test/support/test_seed_helper.ex
defmodule MoomooMarkets.TestSeedHelper do
  alias MoomooMarkets.{
    Repo,
    Accounts.User,
    DataSources.DataSource,
    DataSources.DataSourceCredential,
    Encryption
  }

  def load_seeds do
    seed_path = Application.fetch_env!(:moomoo_markets, MoomooMarkets.Repo)[:seed_path]
    Code.eval_file(seed_path)
  end

  def insert_test_seeds do
    {:ok, user} =
      Repo.insert(%User{
        email: "test@example.com",
        hashed_password: "dummy_hashed_password"
      })

    {:ok, data_source} =
      Repo.insert(%DataSource{
        name: "J-Quants",
        provider_type: "jquants",
        base_url: "http://localhost:4444"
      })

    encrypted_credentials =
      Encryption.encrypt(
        Jason.encode!(%{
          "mailaddress" => "test@example.com",
          "password" => "password"
        })
      )

    {:ok, credential} =
      Repo.insert(%DataSourceCredential{
        user_id: user.id,
        data_source_id: data_source.id,
        encrypted_credentials: encrypted_credentials
      })

    %{
      user: user,
      data_source: data_source,
      credential: credential
    }
  end
end
