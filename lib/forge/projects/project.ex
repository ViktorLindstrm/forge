defmodule Forge.Projects.Project do
  use Ash.Resource,
    domain: Forge.Projects,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer]

  @statuses [:idea, :active, :paused, :done]
  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]
  @currencies ["SEK", "EUR", "USD", "GBP", "NOK", "DKK", "CHF", "JPY", "CAD", "AUD"]

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
    end

    read :list do
      description "Lists projects sorted by sort_order then name"

      prepare fn query, _context ->
        Ash.Query.sort(query, [{:sort_order, :asc}, {:name, :asc}])
      end
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
        :currency,
        :project_group_id,
        :sort_order
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
        :currency,
        :project_group_id,
        :sort_order,
        :tasks_enabled
      ]
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

    prefix "projects"

    publish_all :update, ["project", :id]
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

    attribute :sort_order, :integer do
      public? true
      allow_nil? false
      default 0
    end

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

    attribute :tasks_enabled, :boolean do
      public? true
      allow_nil? false
      default false
    end

    attribute :currency, :string do
      public? true
      allow_nil? false
      default "SEK"
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

  calculations do
    calculate :completion_percentage,
              :float,
              expr(
                if task_count == 0 do
                  nil
                else
                  done_task_count / task_count * 100.0
                end
              )
  end

  aggregates do
    count :task_count, :tasks

    count :done_task_count, :tasks do
      filter expr(status == :done)
    end

    count :bom_item_count, :bom_items

    count :received_bom_item_count, :bom_items do
      filter expr(status == :received)
    end

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
          currency: String.t(),
          sort_order: non_neg_integer(),
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

  @spec currencies() :: [String.t(), ...]
  def currencies, do: @currencies
end
