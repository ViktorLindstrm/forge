defmodule Forge.Projects.BomItem do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer

  @statuses [:needed, :ordered, :received]

  postgres do
    table "bom_items"
    repo Forge.Repo

    references do
      reference :project, on_delete: :delete
    end
  end

  resource do
    description "A bill-of-materials item belonging to a project"
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true
      prepare build(sort: [sort_order: :asc, inserted_at: :asc])
    end

    read :by_project do
      description "Lists all BOM items for a given project"
      argument :project_id, :integer, allow_nil?: false

      filter expr(project_id == ^arg(:project_id))
      prepare build(sort: [sort_order: :asc, inserted_at: :asc])
    end

    create :create do
      accept [
        :name,
        :quantity,
        :unit,
        :supplier,
        :link,
        :unit_price,
        :currency,
        :status,
        :notes,
        :sort_order,
        :project_id
      ]

      change {Forge.Projects.Changes.SetNextSortOrder, filter_attribute: :project_id}
    end

    update :update do
      accept [
        :name,
        :quantity,
        :unit,
        :supplier,
        :link,
        :unit_price,
        :currency,
        :status,
        :notes,
        :sort_order
      ]
    end

    update :toggle_status do
      description "Cycles the status: needed → ordered → received → needed"
      require_atomic? false

      change fn changeset, _context ->
        new_status =
          case changeset.data.status do
            :needed -> :ordered
            :ordered -> :received
            _ -> :needed
          end

        Ash.Changeset.force_change_attribute(changeset, :status, new_status)
      end
    end
  end

  validations do
    validate numericality(:quantity, greater_than: 0)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end

    attribute :quantity, :integer do
      public? true
      allow_nil? false
      default 1
    end

    attribute :unit, :string, public?: true
    attribute :supplier, :string, public?: true
    attribute :link, :string, public?: true
    attribute :unit_price, :decimal, public?: true

    attribute :currency, :string do
      public? true
      allow_nil? false
      default "SEK"
    end

    attribute :status, :atom do
      public? true
      allow_nil? false
      default :needed
      constraints one_of: @statuses
    end

    attribute :notes, :string, public?: true

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

  calculations do
    calculate :total_price,
              :decimal,
              expr(
                if is_nil(unit_price) do
                  nil
                else
                  unit_price * quantity
                end
              )
  end

  @type status :: :needed | :ordered | :received

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          quantity: pos_integer(),
          unit: String.t() | nil,
          supplier: String.t() | nil,
          link: String.t() | nil,
          unit_price: Decimal.t() | nil,
          currency: String.t(),
          status: status(),
          notes: String.t() | nil,
          sort_order: non_neg_integer(),
          project_id: pos_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses
end
