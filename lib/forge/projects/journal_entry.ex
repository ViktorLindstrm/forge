defmodule Forge.Projects.JournalEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          title: String.t() | nil,
          body: String.t() | nil,
          sort_order: non_neg_integer(),
          project_id: pos_integer() | nil,
          project: Forge.Projects.Project.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :id

  schema "journal_entries" do
    field :title, :string
    field :body, :string
    field :sort_order, :integer, default: 0
    belongs_to :project, Forge.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :body, :sort_order, :project_id])
    |> validate_required([:body, :project_id])
    |> validate_length(:body, min: 1)
  end
end
