defmodule Forge.Attachment do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "attachments"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :type,         Forge.AttachmentType, allow_nil?: false, public?: true
    attribute :title,        :string, allow_nil?: false, public?: true
    attribute :description,  :string, public?: true
    attribute :filename,     :string, allow_nil?: false, public?: true
    attribute :content_type, :string, allow_nil?: false, public?: true
    attribute :storage_path, :string, allow_nil?: false, public?: true
    attribute :size_bytes,   :integer, allow_nil?: false, public?: true
    attribute :sort_order,   :integer, default: 0, public?: true
    timestamps()
  end

  relationships do
    belongs_to :project, Forge.Project, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([
        :type, :title, :description, :filename,
        :content_type, :storage_path, :size_bytes,
        :sort_order, :project_id
      ])
    end

    update :update do
      accept([:title, :description, :sort_order])
    end

    read :for_project do
      argument :project_id, :uuid, allow_nil?: false
      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [type: :asc, sort_order: :asc, inserted_at: :asc])
    end
  end

  code_interface do
    define :create,      action: :create
    define :update,      action: :update
    define :destroy,     action: :destroy
    define :for_project, action: :for_project, args: [:project_id]
  end
end
