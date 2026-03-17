defmodule Forge.JournalEntry do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "journal_entries"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, public?: true
    # Kropp är rå Markdown — :::bom-block lever här i MVP
    attribute :body, :string, allow_nil?: false, public?: true
    timestamps()
  end

  relationships do
    belongs_to :project, Forge.Project, allow_nil?: false, public?: true
  end

  # Append-only: ingen :update action — avsiktligt
  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :body, :project_id]
    end

    read :for_project do
      argument :project_id, :uuid, allow_nil?: false
      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [inserted_at: :desc])
    end
  end

  code_interface do
    define :create, action: :create
    define :for_project, action: :for_project, args: [:project_id]
    define :destroy, action: :destroy
  end
end
