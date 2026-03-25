defmodule Forge.Projects.Task do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer

  @statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]

  postgres do
    table "tasks"
    repo Forge.Repo

    references do
      reference :project, on_delete: :delete
      reference :parent_task, on_delete: :delete
    end
  end

  resource do
    description "A task belonging to a project"
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true

      prepare fn query, _context ->
        require Ash.Expr

        Ash.Query.sort(query, [
          {Ash.Expr.calc(
             if pin_status == :current do
               0
             else
               if pin_status == :upcoming do
                 1
               else
                 2
               end
             end,
             type: :integer
           ), :asc},
          {:sort_order, :asc},
          {:inserted_at, :asc}
        ])
      end
    end

    read :by_project do
      description "Lists all tasks for a given project, sorted by pin then sort_order"
      argument :project_id, :integer, allow_nil?: false

      filter expr(project_id == ^arg(:project_id))

      prepare fn query, _context ->
        require Ash.Expr

        Ash.Query.sort(query, [
          {Ash.Expr.calc(
             if pin_status == :current do
               0
             else
               if pin_status == :upcoming do
                 1
               else
                 2
               end
             end,
             type: :integer
           ), :asc},
          {:sort_order, :asc},
          {:inserted_at, :asc}
        ])
      end
    end

    create :create do
      accept [
        :title,
        :description,
        :status,
        :priority,
        :pin_status,
        :due_date,
        :sort_order,
        :project_id,
        :parent_task_id
      ]

      change {Forge.Projects.Changes.SetNextSortOrder, filter_attribute: :project_id}
      change Forge.Projects.Changes.ClearPinStatusIfDone
    end

    update :update do
      accept [
        :title,
        :description,
        :status,
        :priority,
        :pin_status,
        :due_date,
        :sort_order,
        :parent_task_id
      ]

      require_atomic? false
      change Forge.Projects.Changes.ClearPinStatusIfDone
      change Forge.Projects.Changes.UnpinOtherTasks
    end

    update :toggle_done do
      description "Toggles the task between :done and :todo, cascading to subtasks and ancestors"
      require_atomic? false

      change fn changeset, _context ->
        current_status = changeset.data.status
        new_status = if current_status == :done, do: :todo, else: :done
        Ash.Changeset.force_change_attribute(changeset, :status, new_status)
      end

      change Forge.Projects.Changes.ClearPinStatusIfDone
      change Forge.Projects.Changes.CascadeTaskCompletion
    end

    update :pin do
      description "Pins a task as :current or :upcoming (task must not be :done)"
      accept [:pin_status]
      require_atomic? false

      validate Forge.Projects.Validations.TaskNotDone
      change Forge.Projects.Changes.UnpinOtherTasks
    end

    update :unpin do
      description "Removes the pin from a task"
      accept []
      require_atomic? false

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :pin_status, nil)
      end
    end

    update :reorder do
      description "Updates the sort_order of a task"
      accept [:sort_order]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      public? true
      allow_nil? false
    end

    attribute :description, :string, public?: true

    attribute :status, :atom do
      public? true
      allow_nil? false
      default :todo
      constraints one_of: @statuses
    end

    attribute :priority, :atom do
      public? true
      allow_nil? false
      default :medium
      constraints one_of: @priorities
    end

    attribute :pin_status, :atom do
      public? true
      allow_nil? true
      constraints one_of: [:current, :upcoming]
    end

    attribute :due_date, :date, public?: true

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

    belongs_to :parent_task, Forge.Projects.Task do
      public? true
      allow_nil? true
      attribute_type :uuid
    end

    has_many :subtasks, Forge.Projects.Task do
      public? true
      destination_attribute :parent_task_id
    end
  end

  calculations do
    calculate :overdue?,
              :boolean,
              expr(not is_nil(due_date) and status != :done and due_date < today())
  end

  aggregates do
    count :subtask_count, :subtasks

    count :done_subtask_count, :subtasks do
      filter expr(status == :done)
    end
  end

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
          project_id: pos_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec priorities() :: [priority(), ...]
  def priorities, do: @priorities
end
