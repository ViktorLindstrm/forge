defmodule Forge.Projects.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]

  @type status :: :todo | :in_progress | :done | :blocked
  @type priority :: :low | :medium | :high

  @type pin_status :: :current | :upcoming | nil

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          status: status(),
          priority: priority(),
          pin_status: pin_status(),
          due_date: Date.t() | nil,
          sort_order: non_neg_integer(),
          parent_task_id: Ecto.UUID.t() | nil,
          parent_task: t() | Ecto.Association.NotLoaded.t(),
          project_id: pos_integer() | nil,
          project: Forge.Projects.Project.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :id

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, Ecto.Enum, values: @statuses, default: :todo
    field :priority, Ecto.Enum, values: @priorities, default: :medium
    field :pin_status, Ecto.Enum, values: [:current, :upcoming]
    field :due_date, :date
    field :sort_order, :integer, default: 0
    belongs_to :parent_task, __MODULE__, foreign_key: :parent_task_id, type: :binary_id
    belongs_to :project, Forge.Projects.Project
    has_many :subtasks, __MODULE__, foreign_key: :parent_task_id, references: :id

    timestamps(type: :utc_datetime)
  end

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec priorities() :: [priority(), ...]
  def priorities, do: @priorities

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :priority,
      :pin_status,
      :due_date,
      :sort_order,
      :parent_task_id,
      :project_id
    ])
    |> validate_required([:title, :project_id])
  end
end
