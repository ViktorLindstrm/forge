defmodule Forge.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:idea, :active, :paused, :done]
  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]

  @type status :: :idea | :active | :paused | :done
  @type color :: :blue | :violet | :emerald | :amber | :rose | :orange | :sky

  @type pinned_tasks :: %{
          current: Forge.Projects.Task.t() | nil,
          upcoming: Forge.Projects.Task.t() | nil
        }

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          status: status(),
          tech_stack: String.t() | nil,
          url: String.t() | nil,
          notes: String.t() | nil,
          color: color(),
          budget: Decimal.t() | nil,
          project_group_id: pos_integer() | nil,
          project_group: Forge.Projects.ProjectGroup.t() | Ecto.Association.NotLoaded.t(),
          pinned_tasks: pinned_tasks() | nil,
          tasks: [Forge.Projects.Task.t()] | Ecto.Association.NotLoaded.t(),
          bom_items: [Forge.Projects.BomItem.t()] | Ecto.Association.NotLoaded.t(),
          journal_entries: [Forge.Projects.JournalEntry.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "projects" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: @statuses, default: :idea
    field :tech_stack, :string
    field :url, :string
    field :notes, :string
    field :color, Ecto.Enum, values: @colors, default: :blue
    field :budget, :decimal
    belongs_to :project_group, Forge.Projects.ProjectGroup
    field :pinned_tasks, :map, virtual: true

    has_many :tasks, Forge.Projects.Task
    has_many :bom_items, Forge.Projects.BomItem
    has_many :journal_entries, Forge.Projects.JournalEntry

    timestamps(type: :utc_datetime)
  end

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec colors() :: [color(), ...]
  def colors, do: @colors

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :name,
      :description,
      :status,
      :tech_stack,
      :url,
      :notes,
      :color,
      :budget,
      :project_group_id
    ])
    |> validate_required([:name])
    |> validate_format(:url, ~r/^https?:\/\/.+/, message: "must start with http:// or https://")
    |> validate_length(:name, max: 100)
  end
end
