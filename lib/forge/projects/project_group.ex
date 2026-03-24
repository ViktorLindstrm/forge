defmodule Forge.Projects.ProjectGroup do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "project_groups"
    repo Forge.Repo
  end

  resource do
    description "A named grouping for projects"
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true

      prepare fn query, _context ->
        Ash.Query.sort(query, name: :asc)
      end
    end

    create :create do
      accept [:name]
    end

    update :update do
      accept [:name]
    end
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
      constraints max_length: 100
    end

    timestamps type: :utc_datetime
  end

  relationships do
    has_many :projects, Forge.Projects.Project do
      public? true
    end
  end

  identities do
    identity :unique_name, [:name]
  end

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
