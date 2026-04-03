defmodule Forge.Projects.JournalEntry do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer]

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
    end

    read :by_project do
      description "Lists journal entries for a given project, newest first"
      argument :project_id, :integer, allow_nil?: false

      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [sort_order: :desc, inserted_at: :desc])

      pagination offset?: true, countable: true, required?: false
    end

    create :create do
      accept [:body, :sort_order, :project_id]
      change {Forge.Projects.Changes.SetNextSortOrder, filter_attribute: :project_id}
    end

    update :update do
      accept [:body]
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  pub_sub do
    module ForgeWeb.Endpoint

    broadcast_type :notification

    prefix "journal_entries"

    publish :create, ["project", :project_id]
    publish_all :update, ["project", :project_id]
    publish :destroy, ["project", :project_id]
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
