defmodule Forge.Task do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tasks"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :title,      :string,            allow_nil?: false, public?: true
    attribute :status,     Forge.TaskStatus,   default: :todo,   allow_nil?: false, public?: true
    attribute :priority,   Forge.TaskPriority, default: :medium, allow_nil?: false, public?: true
    attribute :due_date,   :date,              public?: true
    attribute :sort_order, :integer,           default: 0,       public?: true
    timestamps()
  end

  relationships do
    belongs_to :project,       Forge.Project,      allow_nil?: false, public?: true
    belongs_to :journal_entry, Forge.JournalEntry, allow_nil?: true,  public?: true

    many_to_many :tags, Forge.Tag,
      through: Forge.TaskTag,
      source_attribute_on_join_resource: :task_id,
      destination_attribute_on_join_resource: :tag_id,
      public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([
        :title, :status, :priority, :due_date,
        :sort_order, :project_id, :journal_entry_id
      ])
    end

    update :update do
      accept([:title, :status, :priority, :due_date, :sort_order])
    end

    update :toggle do
      require_atomic? false
      change fn changeset, _ctx ->
        current = Ash.Changeset.get_attribute(changeset, :status)
        new_status = if current == :done, do: :todo, else: :done
        Ash.Changeset.change_attribute(changeset, :status, new_status)
      end
    end

    update :reorder do
      accept([:sort_order])
    end

    read :for_project do
      argument :project_id, :uuid, allow_nil?: false
      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [sort_order: :asc, inserted_at: :asc])
    end
  end

  code_interface do
    define :create,      action: :create
    define :update,      action: :update
    define :toggle,      action: :toggle
    define :reorder,     action: :reorder
    define :destroy,     action: :destroy
    define :for_project, action: :for_project, args: [:project_id]
    define :get_by_id,   action: :read, get_by: [:id]
  end
end
