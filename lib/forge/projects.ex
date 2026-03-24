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
    Ash.read!(ProjectGroup)
  end

  @spec get_project_group!(pos_integer()) :: ProjectGroup.t()
  def get_project_group!(id), do: Ash.get!(ProjectGroup, id)

  @spec create_project_group(map()) :: {:ok, ProjectGroup.t()} | {:error, Ash.Error.t()}
  def create_project_group(attrs \\ %{}) do
    ProjectGroup
    |> Ash.Changeset.for_create(:create, atomize(attrs))
    |> Ash.create()
  end

  @spec update_project_group(ProjectGroup.t(), map()) ::
          {:ok, ProjectGroup.t()} | {:error, Ash.Error.t()}
  def update_project_group(%ProjectGroup{} = group, attrs) do
    group
    |> Ash.Changeset.for_update(:update, atomize(attrs))
    |> Ash.update()
  end

  @spec delete_project_group(ProjectGroup.t()) ::
          {:ok, ProjectGroup.t()} | {:error, Ash.Error.t()}
  def delete_project_group(%ProjectGroup{} = group) do
    case Ash.destroy(group, return_destroyed?: true) do
      :ok -> {:ok, group}
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec change_project_group(ProjectGroup.t(), map()) :: AshPhoenix.Form.t()
  def change_project_group(%ProjectGroup{} = group, attrs \\ %{}) do
    AshPhoenix.Form.for_update(group, :update, params: stringify(attrs), domain: __MODULE__)
  end

  # ── Projects ──────────────────────────────────────────────────────────────

  @spec list_projects() :: [Project.t()]
  def list_projects do
    Project
    |> Ash.Query.load([:current_task, :upcoming_task])
    |> Ash.read!()
  end

  @type grouped_projects :: [{ProjectGroup.t() | nil, [Project.t()]}]

  @spec list_projects_grouped() :: grouped_projects()
  def list_projects_grouped do
    groups = list_project_groups()
    projects = list_projects()

    by_group = Enum.group_by(projects, & &1.project_group_id)

    grouped =
      Enum.flat_map(groups, fn group ->
        [{group, Map.get(by_group, group.id, [])}]
      end)

    ungrouped = Map.get(by_group, nil, [])

    if ungrouped == [] do
      grouped
    else
      grouped ++ [{nil, ungrouped}]
    end
  end

  @spec list_projects_by_status(project_status()) :: [Project.t()]
  def list_projects_by_status(status) do
    Project
    |> Ash.Query.filter(status == ^status)
    |> Ash.Query.load([:current_task, :upcoming_task])
    |> Ash.read!()
  end

  @spec get_project!(project_id()) :: Project.t()
  def get_project!(id), do: Ash.get!(Project, id)

  @spec create_project(map()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def create_project(attrs \\ %{}) do
    Project
    |> Ash.Changeset.for_create(:create, atomize(attrs))
    |> Ash.create()
  end

  @spec update_project(Project.t(), map()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def update_project(%Project{} = project, attrs) do
    project
    |> Ash.Changeset.for_update(:update, atomize(attrs))
    |> Ash.update()
  end

  @spec delete_project(Project.t()) :: {:ok, Project.t()} | {:error, Ash.Error.t()}
  def delete_project(%Project{} = project) do
    case Ash.destroy(project, return_destroyed?: true) do
      :ok -> {:ok, project}
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec change_project(Project.t(), map()) :: Phoenix.HTML.Form.t()
  def change_project(%Project{} = project, attrs \\ %{}) do
    AshPhoenix.Form.for_update(project, :update,
      params: stringify(attrs),
      domain: __MODULE__,
      as: "project"
    )
    |> Phoenix.Component.to_form()
  end

  @spec count_by_status() :: status_counts()
  def count_by_status do
    Ash.read!(Project)
    |> Enum.group_by(& &1.status)
    |> Map.new(fn {status, projects} -> {status, length(projects)} end)
  end

  # ── Tasks ─────────────────────────────────────────────────────────────────

  @spec list_tasks(project_id()) :: [Task.t()]
  def list_tasks(project_id) do
    Task
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.read!()
  end

  @spec list_tasks_with_subtasks(project_id()) :: [Task.t()]
  def list_tasks_with_subtasks(project_id) do
    tasks = list_tasks(project_id)

    subtasks_by_parent =
      tasks
      |> Enum.reject(&is_nil(&1.parent_task_id))
      |> Enum.group_by(& &1.parent_task_id)

    tasks
    |> Enum.filter(&is_nil(&1.parent_task_id))
    |> Enum.flat_map(fn task ->
      children = Map.get(subtasks_by_parent, task.id, [])
      [Map.put(task, :subtasks, children) | Enum.map(children, &Map.put(&1, :subtasks, []))]
    end)
  end

  @spec list_tasks_tree(project_id()) :: [{Task.t(), [Task.t()]}]
  def list_tasks_tree(project_id) do
    tasks = list_tasks(project_id)
    groups = Enum.group_by(tasks, & &1.parent_task_id)
    parents = Map.get(groups, nil, [])

    Enum.map(parents, fn parent ->
      {parent, Map.get(groups, parent.id, [])}
    end)
  end

  @spec list_subtasks(task_id()) :: [Task.t()]
  def list_subtasks(task_id) do
    Task
    |> Ash.Query.filter(parent_task_id == ^task_id)
    |> Ash.Query.sort(sort_order: :asc, inserted_at: :asc)
    |> Ash.read!()
  end

  @spec toggle_task_done(task_id() | Task.t()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def toggle_task_done(id) when is_binary(id) do
    id
    |> get_task!()
    |> toggle_task_done()
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

  @spec get_task!(task_id()) :: Task.t()
  def get_task!(id), do: Ash.get!(Task, id)

  @spec create_task(map()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def create_task(attrs) do
    Task
    |> Ash.Changeset.for_create(:create, atomize(attrs))
    |> Ash.create()
  end

  @spec update_task(Task.t(), map()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def update_task(%Task{} = task, attrs) do
    task
    |> Ash.Changeset.for_update(:update, atomize(attrs))
    |> Ash.update()
  end

  @spec delete_task(Task.t()) :: {:ok, Task.t()} | {:error, Ash.Error.t()}
  def delete_task(%Task{} = task) do
    case Ash.destroy(task, return_destroyed?: true) do
      :ok -> {:ok, task}
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec change_task(Task.t(), map()) :: Phoenix.HTML.Form.t()
  def change_task(%Task{} = task, attrs \\ %{}) do
    AshPhoenix.Form.for_update(task, :update,
      params: stringify(attrs),
      domain: __MODULE__,
      as: "task"
    )
    |> Phoenix.Component.to_form()
  end

  @spec task_stats(project_id()) :: task_stats()
  def task_stats(project_id) do
    Task
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.read!()
    |> Enum.group_by(& &1.status)
    |> Map.new(fn {status, tasks} -> {status, length(tasks)} end)
  end

  @spec reorder_tasks(project_id(), [Ecto.UUID.t()]) :: :ok
  def reorder_tasks(_project_id, ordered_ids) when is_list(ordered_ids) do
    ordered_ids
    |> Enum.with_index(1)
    |> Enum.each(fn {id, sort_order} ->
      task = Ash.get!(Task, id)

      task
      |> Ash.Changeset.for_update(:reorder, %{sort_order: sort_order})
      |> Ash.update!(authorize?: false)
    end)

    :ok
  end

  @spec reorder_subtasks(Ecto.UUID.t(), [Ecto.UUID.t()]) :: :ok
  def reorder_subtasks(_parent_task_id, ordered_ids) when is_list(ordered_ids) do
    ordered_ids
    |> Enum.with_index(1)
    |> Enum.each(fn {id, sort_order} ->
      task = Ash.get!(Task, id)

      task
      |> Ash.Changeset.for_update(:reorder, %{sort_order: sort_order})
      |> Ash.update!(authorize?: false)
    end)

    :ok
  end

  # ── BOM Items ─────────────────────────────────────────────────────────────

  @spec list_bom_items(project_id()) :: [BomItem.t()]
  def list_bom_items(project_id) do
    BomItem
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.read!()
  end

  @spec get_bom_item!(bom_item_id()) :: BomItem.t()
  def get_bom_item!(id), do: Ash.get!(BomItem, id)

  @spec create_bom_item(map()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def create_bom_item(attrs) do
    BomItem
    |> Ash.Changeset.for_create(:create, atomize(attrs))
    |> Ash.create()
  end

  @spec update_bom_item(BomItem.t(), map()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def update_bom_item(%BomItem{} = item, attrs) do
    item
    |> Ash.Changeset.for_update(:update, atomize(attrs))
    |> Ash.update()
  end

  @spec delete_bom_item(BomItem.t()) :: {:ok, BomItem.t()} | {:error, Ash.Error.t()}
  def delete_bom_item(%BomItem{} = item) do
    case Ash.destroy(item, return_destroyed?: true) do
      :ok -> {:ok, item}
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec change_bom_item(BomItem.t(), map()) :: AshPhoenix.Form.t()
  def change_bom_item(%BomItem{} = item, attrs \\ %{}) do
    AshPhoenix.Form.for_update(item, :update, params: stringify(attrs), domain: __MODULE__)
  end

  @spec bom_budget(project_id()) :: bom_budget()
  def bom_budget(project_id) do
    items =
      BomItem
      |> Ash.Query.filter(project_id == ^project_id)
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
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.read!()
  end

  @spec list_journal_entries_page(project_id(), pos_integer(), pos_integer()) ::
          [JournalEntry.t()]
  def list_journal_entries_page(project_id, page, per_page) do
    JournalEntry
    |> Ash.Query.filter(project_id == ^project_id)
    |> Ash.Query.limit(per_page)
    |> Ash.Query.offset((page - 1) * per_page)
    |> Ash.read!()
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
    |> Ash.Changeset.for_create(:create, atomize(attrs))
    |> Ash.create()
  end

  @spec update_journal_entry(JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()} | {:error, Ash.Error.t()}
  def update_journal_entry(%JournalEntry{} = entry, attrs) do
    entry
    |> Ash.Changeset.for_update(:update, atomize(attrs))
    |> Ash.update()
  end

  @spec delete_journal_entry(JournalEntry.t()) ::
          {:ok, JournalEntry.t()} | {:error, Ash.Error.t()}
  def delete_journal_entry(%JournalEntry{} = entry) do
    case Ash.destroy(entry, return_destroyed?: true) do
      :ok -> {:ok, entry}
      {:ok, destroyed} -> {:ok, destroyed}
      err -> err
    end
  end

  @spec change_journal_entry(JournalEntry.t(), map()) :: AshPhoenix.Form.t()
  def change_journal_entry(%JournalEntry{} = entry, attrs \\ %{}) do
    AshPhoenix.Form.for_update(entry, :update, params: stringify(attrs), domain: __MODULE__)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  @spec atomize(map()) :: map()
  defp atomize(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} -> {k, v}
    end)
  rescue
    ArgumentError ->
      attrs
  end

  @spec stringify(map()) :: map()
  defp stringify(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {k, v} when is_atom(k) -> {to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
end
