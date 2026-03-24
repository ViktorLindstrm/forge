defmodule Forge.Projects.Project do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer

  @statuses [:idea, :active, :paused, :done]
  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]

  postgres do
    table "projects"
    repo Forge.Repo

    references do
      reference :project_group, on_delete: :nilify
    end
  end

  resource do
    description "A project being tracked in Forge"
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true
      prepare Forge.Projects.Preparations.SortProjectsByStatus
    end

    create :create do
      accept [
        :name,
        :description,
        :status,
        :tech_stack,
        :url,
        :notes,
        :color,
        :budget,
        :project_group_id
      ]
    end

    update :update do
      accept [
        :name,
        :description,
        :status,
        :tech_stack,
        :url,
        :notes,
        :color,
        :budget,
        :project_group_id
      ]
    end
  end

  validations do
    validate match(:url, ~r/^https?:\/\/.+/),
      where: [present(:url), changing(:url)],
      message: "must start with http:// or https://"
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
      constraints max_length: 100
    end

    attribute :description, :string, public?: true
    attribute :tech_stack, :string, public?: true
    attribute :url, :string, public?: true
    attribute :notes, :string, public?: true
    attribute :budget, :decimal, public?: true

    attribute :status, :atom do
      public? true
      allow_nil? false
      default :idea
      constraints one_of: @statuses
    end

    attribute :color, :atom do
      public? true
      allow_nil? false
      default :blue
      constraints one_of: @colors
    end

    timestamps type: :utc_datetime
  end

  relationships do
    belongs_to :project_group, Forge.Projects.ProjectGroup do
      public? true
      allow_nil? true
      attribute_type :integer
    end

    has_many :tasks, Forge.Projects.Task do
      public? true
    end

    has_one :current_task, Forge.Projects.Task do
      public? true
      filter expr(pin_status == :current)
    end

    has_one :upcoming_task, Forge.Projects.Task do
      public? true
      filter expr(pin_status == :upcoming)
    end

    has_many :bom_items, Forge.Projects.BomItem do
      public? true
    end

    has_many :journal_entries, Forge.Projects.JournalEntry do
      public? true
    end
  end

  aggregates do
    count :task_count, :tasks

    count :done_task_count, :tasks do
      filter expr(status == :done)
    end

    count :bom_item_count, :bom_items
    count :journal_entry_count, :journal_entries
  end

  @type status :: :idea | :active | :paused | :done
  @type color :: :blue | :violet | :emerald | :amber | :rose | :orange | :sky

  @type pinned_task :: Forge.Projects.Task.t() | nil

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
          current_task: pinned_task(),
          upcoming_task: pinned_task(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec colors() :: [color(), ...]
  def colors, do: @colors
end
