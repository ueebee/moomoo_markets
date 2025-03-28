defmodule MoomooMarkets.Jobs.JobGroupDependency do
  @moduledoc """
  JobGroupDependency represents a dependency relationship between two job groups.
  It ensures that a job group only runs after its dependencies are completed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "job_group_dependencies" do
    # Associations
    belongs_to :job_group, MoomooMarkets.Jobs.JobGroup, foreign_key: :job_group_id
    belongs_to :depends_on, MoomooMarkets.Jobs.JobGroup, foreign_key: :depends_on_id

    timestamps()
  end

  @required_fields [:job_group_id, :depends_on_id]

  def changeset(dependency, attrs) do
    dependency
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_no_self_dependency()
    |> validate_no_circular_dependency()
    |> unique_constraint([:job_group_id, :depends_on_id])
  end

  defp validate_no_self_dependency(changeset) do
    job_group_id = get_field(changeset, :job_group_id)
    depends_on_id = get_field(changeset, :depends_on_id)

    if job_group_id == depends_on_id do
      add_error(changeset, :depends_on_id, "cannot depend on itself")
    else
      changeset
    end
  end

  defp validate_no_circular_dependency(changeset) do
    job_group_id = get_field(changeset, :job_group_id)
    depends_on_id = get_field(changeset, :depends_on_id)

    if would_create_cycle?(job_group_id, depends_on_id) do
      add_error(changeset, :depends_on_id, "would create circular dependency")
    else
      changeset
    end
  end

  defp would_create_cycle?(job_group_id, depends_on_id) do
    # Check if the dependency would create a cycle
    # This is a simplified check - you might want to implement a more thorough cycle detection
    MoomooMarkets.Repo.get_by(__MODULE__, job_group_id: depends_on_id, depends_on_id: job_group_id) != nil
  end
end
