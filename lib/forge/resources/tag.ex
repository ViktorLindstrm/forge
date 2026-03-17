defmodule Forge.Tag do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tags"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    timestamps()
  end

  relationships do
    belongs_to :project, Forge.Project, allow_nil?: false, public?: true
    many_to_many :tasks, Forge.Task,
      through: Forge.TaskTag,
      source_attribute_on_join_resource: :tag_id,
      destination_attribute_on_join_resource: :task_id,
      public?: true
  end

  identities do
    identity :unique_name_per_project, [:name, :project_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([:name, :project_id])
    end

    read :for_project do
      argument :project_id, :uuid, allow_nil?: false
      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [name: :asc])
    end
  end

  code_interface do
    define :create,      action: :create
    define :destroy,     action: :destroy
    define :for_project, action: :for_project, args: [:project_id]
  end
end
