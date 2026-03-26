defmodule Forge.Projects do
  @moduledoc """
  The Projects domain. Manages personal projects and all sub-resources.
  """

  use Ash.Domain

  require Ash.Query

  resources do
    resource Forge.Projects.Project
    resource Forge.Projects.ProjectGroup
    resource Forge.Projects.Task
    resource Forge.Projects.BomItem
    resource Forge.Projects.JournalEntry
  end

  alias Forge.Projects.Project
  alias Forge.Projects.ProjectGroup
  alias Forge.Projects.Task
  alias Forge.Projects.BomItem
  alias Forge.Projects.JournalEntry

  @type project_id :: pos_integer()
  @type task_id :: Ecto.UUID.t()
  @type bom_item_id :: Ecto.UUID.t()
  @type journal_entry_id :: Ecto.UUID.t()

  @type bom_budget :: %{
          required(:total) => Decimal.t(),
          required(:spent) => Decimal.t(),
          required(:items) => [BomItem.t()]
        }

  @type project_status :: Project.status()
  @type task_status :: Task.status()
  @type task_stats :: %{task_status() => non_neg_integer()}
  @type status_counts :: %{Project.status() => non_neg_integer()}

  # ── Project Groups ────────────────────────────────────────────────────────

  @spec list_project_groups() :: [ProjectGroup.t()]
  def list_project_groups do
    ProjectGroup
    |> Ash.Query.for_read(:list, %{})
    |> Ash.read!()
  end

  @spec create_project_group(map()) :: {:ok, ProjectGroup.t()} | {:error, Ash.Error.t()}
  def create_project_group(attrs \\ %{}) do
    ProjectGroup
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec delete_project_group(ProjectGroup.t()) ::
          {:ok, ProjectGroup.t()} | {:error, Ash.Error.t()}
  def delete_project_group(%ProjectGroup{} = group) do
    case Ash.destroy(group, return_destroyed?: true) do
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  # ── Projects ──────────────────────────────────────────────────────────────

  @spec list_projects() :: [Project.t()]
  def list_projects do
    Project
    |> Ash.Query.for_read(:list, %{})
    |> Ash.Query.load([:current_task, :upcoming_task, :project_group])
    |> Ash.read!()
  end

  @type grouped_projects :: [{ProjectGroup.t() | nil, [Project.t()]}]

  @spec list_projects_grouped() :: grouped_projects()
  def list_projects_grouped do
    projects = list_projects()

    by_group = Enum.group_by(projects, & &1.project_group)

    groups =
      by_group
      |> Map.keys()
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(& &1.name)

    grouped = Enum.map(groups, fn group -> {group, Map.get(by_group, group, [])} end)
    ungrouped = Map.get(by_group, nil, [])

    if ungrouped == [] do
      grouped
    else
      grouped ++ [{nil, ungrouped}]
    end
  end

  @spec get_project!(project_id()) :: Project.t()
  def get_project!(id), do: Ash.get!(Project, id)

  @spec create_project(map()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def create_project(attrs \\ %{}) do
    Project
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec update_project(Project.t(), map()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def update_project(%Project{} = project, attrs) do
    project
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  @spec delete_project(Project.t()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def delete_project(%Project{} = project) do
    case Ash.destroy(project, return_destroyed?: true) do
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec count_by_status() :: status_counts()
  def count_by_status do
    aggregates =
      Enum.map(Project.statuses(), fn status ->
        Ash.Query.Aggregate.new!(Project, :"count_#{status}", :count,
          query: [filter: [status: status]],
          default: 0
        )
      end)

    {:ok, result} = Ash.aggregate(Project, aggregates)

    Enum.into(Project.statuses(), %{}, fn status ->
      {status, Map.get(result, :"count_#{status}", 0)}
    end)
  end

  # ── Tasks ─────────────────────────────────────────────────────────────────

  @spec list_tasks(project_id()) :: [Task.t()]
  def list_tasks(project_id) do
    Task
    |> Ash.Query.for_read(:by_project, %{project_id: project_id})
    |> Ash.read!()
  end

  @spec list_tasks_with_subtasks(project_id()) :: [Task.t()]
  def list_tasks_with_subtasks(project_id) do
    Task
    |> Ash.Query.for_read(:by_project, %{project_id: project_id})
    |> Ash.Query.load(:subtasks)
    |> Ash.read!()
    |> Enum.filter(&is_nil(&1.parent_task_id))
    |> Enum.flat_map(fn task -> [task | task.subtasks || []] end)
  end

  @spec get_task!(task_id()) :: Task.t()
  def get_task!(id), do: Ash.get!(Task, id)

  @spec create_task(map()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def create_task(attrs) do
    Task
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec update_task(Task.t(), map()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def update_task(%Task{} = task, attrs) do
    task
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  @spec delete_task(Task.t()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def delete_task(%Task{} = task) do
    case Ash.destroy(task, return_destroyed?: true) do
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec toggle_task_done(task_id() | Task.t()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def toggle_task_done(id) when is_binary(id) do
    id |> get_task!() |> toggle_task_done()
  end

  def toggle_task_done(%Task{} = task) do
    task
    |> Ash.Changeset.for_update(:toggle_done, %{})
    |> Ash.update()
  end

  @spec pin_task(task_id(), :current | :upcoming) ::
          {:ok, Task.t()} | {:error, Ash.Error.t()}
  def pin_task(id, pin_status) when pin_status in [:current, :upcoming] do
    get_task!(id)
    |> Ash.Changeset.for_update(:pin, %{pin_status: pin_status})
    |> Ash.update()
  end

  @spec unpin_task(task_id()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def unpin_task(id) do
    get_task!(id)
    |> Ash.Changeset.for_update(:unpin, %{})
    |> Ash.update()
  end

  @spec task_stats(project_id()) :: task_stats()
  def task_stats(project_id) do
    query =
      Task
      |> Ash.Query.filter(project_id == ^project_id)

    Enum.into(Task.statuses(), %{}, fn status ->
      count =
        query
        |> Ash.Query.filter(status == ^status)
        |> Ash.count!()

      {status, count}
    end)
  end

  @spec reorder_tasks(project_id(), [Ecto.UUID.t() | String.t()]) :: :ok
  def reorder_tasks(_project_id, ordered_ids), do: bulk_apply_sort_orders(ordered_ids)

  @spec reorder_subtasks(Ecto.UUID.t(), [Ecto.UUID.t() | String.t()]) :: :ok
  def reorder_subtasks(_parent_task_id, ordered_ids), do: bulk_apply_sort_orders(ordered_ids)

  @spec bulk_apply_sort_orders([Ecto.UUID.t() | String.t()]) :: :ok
  defp bulk_apply_sort_orders([]), do: :ok

  defp bulk_apply_sort_orders(ordered_ids) when is_list(ordered_ids) do
    Forge.Repo.transaction(fn ->
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      params =
        ordered_ids
        |> Enum.with_index(1)
        |> Enum.map(fn {id, sort_order} ->
          %{id: Ecto.UUID.dump!(id), sort_order: sort_order}
        end)

      values = Enum.with_index(params, 1)

      set_status =
        Enum.map_join(values, " ", fn {_row, i} ->
          "WHEN id = $#{2 * i - 1}::uuid THEN $#{2 * i}::int"
        end)

      ids_in =
        Enum.map_join(values, ", ", fn {_row, i} -> "$#{2 * i - 1}::uuid" end)

      args =
        params
        |> Enum.flat_map(fn %{id: id, sort_order: sort_order} -> [id, sort_order] end)

      query =
        "UPDATE tasks SET sort_order = CASE #{set_status} ELSE sort_order END, updated_at = $#{length(args) + 1} WHERE id IN (#{ids_in})"

      Ecto.Adapters.SQL.query!(Forge.Repo, query, args ++ [now])
    end)

    :ok
  end

  # ── BOM Items ─────────────────────────────────────────────────────────────

  @spec get_bom_item!(bom_item_id()) :: BomItem.t()
  def get_bom_item!(id), do: Ash.get!(BomItem, id)

  @spec create_bom_item(map()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def create_bom_item(attrs) do
    BomItem
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec update_bom_item(BomItem.t(), map()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def update_bom_item(%BomItem{} = item, attrs) do
    item
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  @spec toggle_bom_item_status(BomItem.t()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def toggle_bom_item_status(%BomItem{} = item) do
    item
    |> Ash.Changeset.for_update(:toggle_status, %{})
    |> Ash.update()
  end

  @spec delete_bom_item(BomItem.t()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def delete_bom_item(%BomItem{} = item) do
    case Ash.destroy(item, return_destroyed?: true) do
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec bom_budget(project_id()) :: bom_budget()
  def bom_budget(project_id) do
    items =
      BomItem
      |> Ash.Query.for_read(:by_project, %{project_id: project_id})
      |> Ash.Query.load([:total_price])
      |> Ash.read!()

    total =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, item.total_price || Decimal.new(0))
      end)

    spent =
      items
      |> Enum.filter(&(&1.status in [:ordered, :received]))
      |> Enum.reduce(Decimal.new(0), fn item, acc ->
        Decimal.add(acc, item.total_price || Decimal.new(0))
      end)

    %{total: total, spent: spent, items: items}
  end

  # ── Journal Entries ───────────────────────────────────────────────────────

  @spec list_journal_entries(project_id()) :: [JournalEntry.t()]
  def list_journal_entries(project_id) do
    JournalEntry
    |> Ash.Query.for_read(:by_project, %{project_id: project_id})
    |> Ash.read!()
  end

  @spec list_journal_entries_page(project_id(), pos_integer(), pos_integer()) ::
          [JournalEntry.t()]
  def list_journal_entries_page(project_id, page, per_page) do
    result =
      JournalEntry
      |> Ash.Query.for_read(:by_project, %{project_id: project_id})
      |> Ash.read!(page: [offset: (page - 1) * per_page, limit: per_page])

    result.results
  end

  @spec count_journal_entries(project_id()) :: non_neg_integer()
  def count_journal_entries(project_id) do
    JournalEntry
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.count!()
  end

  @spec get_journal_entry!(journal_entry_id()) :: JournalEntry.t()
  def get_journal_entry!(id), do: Ash.get!(JournalEntry, id)

  @spec create_journal_entry(map()) ::
          {:ok, JournalEntry.t()} | {:error, Ash.Error.t()}
  def create_journal_entry(attrs) do
    JournalEntry
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec delete_journal_entry(JournalEntry.t()) ::
          {:ok, JournalEntry.t()} | {:error, Ash.Error.t()}
  def delete_journal_entry(%JournalEntry{} = entry) do
    case Ash.destroy(entry, return_destroyed?: true) do
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end
end
