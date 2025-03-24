defmodule MoomooMarkets.DataSources.DataSourceCredential do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_source_credentials" do
    field :encrypted_credentials, :binary
    field :refresh_token, :string
    field :refresh_token_expired_at, :utc_datetime
    field :id_token, :string
    field :id_token_expired_at, :utc_datetime

    belongs_to :user, MoomooMarkets.Accounts.User
    belongs_to :data_source, MoomooMarkets.DataSources.DataSource

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data_source_credential, attrs) do
    data_source_credential
    |> cast(attrs, [:encrypted_credentials, :refresh_token, :refresh_token_expired_at, :id_token, :id_token_expired_at, :user_id, :data_source_id])
    |> validate_required([:encrypted_credentials, :user_id, :data_source_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:data_source_id)
    |> unique_constraint([:user_id, :data_source_id])
  end
end
