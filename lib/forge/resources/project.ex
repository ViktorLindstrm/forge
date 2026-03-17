defmodule Forge.Project do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "projects"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :name,            :string, allow_nil?: false, public?: true
    attribute :description,     :string, public?: true
    attribute :status,          Forge.ProjectStatus, default: :idea, allow_nil?: false, public?: true
    attribute :cover_image_id,  :uuid, public?: true
    timestamps()
  end

  relationships do
    belongs_to :category, Forge.Category, allow_nil?: false, public?: true
    has_many :bom_items,       Forge.BomItem,       public?: true
    has_many :journal_entries, Forge.JournalEntry,  public?: true
    has_many :attachments,     Forge.Attachment,    public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([:name, :description, :status, :category_id])
    end

    update :update do
      accept([:name, :description, :status, :category_id])
    end

    update :set_cover do
      argument :attachment_id, :uuid, allow_nil?: true
      change set_attribute(:cover_image_id, arg(:attachment_id))
    end

    read :list do
      prepare build(sort: [inserted_at: :desc])
    end

    read :list_by_category do
      argument :category_id, :uuid, allow_nil?: false
      filter expr(category_id == ^arg(:category_id))
      prepare build(sort: [inserted_at: :desc])
    end
  end

  code_interface do
    define :create,            action: :create
    define :update,            action: :update
    define :set_cover,         action: :set_cover, args: [:attachment_id]
    define :list,              action: :list
    define :list_by_category,  action: :list_by_category, args: [:category_id]
    define :get_by_id,         action: :read, get_by: [:id]
    define :destroy,           action: :destroy
  end
end
