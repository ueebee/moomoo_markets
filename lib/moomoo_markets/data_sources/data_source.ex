defmodule MoomooMarkets.DataSources.DataSource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_sources" do
    field :name, :string
    field :description, :string
    field :provider_type, :string
    field :is_enabled, :boolean, default: false
    field :base_url, :string
    field :api_version, :string
    field :rate_limit_per_minute, :integer
    field :rate_limit_per_hour, :integer
    field :rate_limit_per_day, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data_source, attrs) do
    data_source
    |> cast(attrs, [:name, :description, :provider_type, :is_enabled, :base_url, :api_version, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day])
    |> validate_required([:name, :description, :provider_type, :is_enabled, :base_url, :api_version, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day])
  end
end
