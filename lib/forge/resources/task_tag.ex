defmodule Forge.TaskTag do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "task_tags"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :task, Forge.Task, allow_nil?: false, primary_key?: true, public?: true
    belongs_to :tag,  Forge.Tag,  allow_nil?: false, primary_key?: true, public?: true
  end

  identities do
    identity :unique_task_tag, [:task_id, :tag_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([:task_id, :tag_id])
    end
  end

  code_interface do
    define :create,  action: :create
    define :destroy, action: :destroy
  end
end
