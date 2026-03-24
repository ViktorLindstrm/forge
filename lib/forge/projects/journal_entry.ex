defmodule Forge.Projects.JournalEntry do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "journal_entries"
    repo Forge.Repo

    references do
      reference :project, on_delete: :delete
    end
  end

  resource do
    description "A journal/notes entry attached to a project"
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true

      prepare fn query, _context ->
        Ash.Query.sort(query, sort_order: :desc, inserted_at: :desc)
      end
    end

    create :create do
      accept [:title, :body, :sort_order, :project_id]
      change {Forge.Projects.Changes.SetNextSortOrder, filter_attribute: :project_id}
    end

    update :update do
      accept [:title, :body, :sort_order]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, public?: true

    attribute :body, :string do
      public? true
      allow_nil? false
      constraints min_length: 1
    end

    attribute :sort_order, :integer do
      public? true
      allow_nil? false
      default 0
    end

    timestamps type: :utc_datetime
  end

  relationships do
    belongs_to :project, Forge.Projects.Project do
      public? true
      allow_nil? false
      attribute_type :integer
    end
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          title: String.t() | nil,
          body: String.t() | nil,
          sort_order: non_neg_integer(),
          project_id: pos_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
