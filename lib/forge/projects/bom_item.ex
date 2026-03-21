defmodule Forge.Projects.BomItem do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:needed, :ordered, :received]

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
          project: Forge.Projects.Project.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :id

  schema "bom_items" do
    field :name, :string
    field :quantity, :integer, default: 1
    field :unit, :string
    field :supplier, :string
    field :link, :string
    field :unit_price, :decimal
    field :currency, :string, default: "SEK"
    field :status, Ecto.Enum, values: @statuses, default: :needed
    field :notes, :string
    field :sort_order, :integer, default: 0
    belongs_to :project, Forge.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
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
    ])
    |> validate_required([:name, :project_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end
