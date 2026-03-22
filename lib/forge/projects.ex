defmodule Forge.Projects do
  @moduledoc """
  The Projects context. Manages personal projects and all sub-resources.
  """

  import Ecto.Query, warn: false
  alias Forge.Repo

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
    |> order_by([g], asc: g.name)
    |> Repo.all()
  end

  @spec get_project_group!(pos_integer()) :: ProjectGroup.t()
  def get_project_group!(id), do: Repo.get!(ProjectGroup, id)

  @spec create_project_group(map()) :: {:ok, ProjectGroup.t()} | {:error, Ecto.Changeset.t()}
  def create_project_group(attrs \\ %{}) do
    %ProjectGroup{}
    |> ProjectGroup.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_project_group(ProjectGroup.t(), map()) ::
          {:ok, ProjectGroup.t()} | {:error, Ecto.Changeset.t()}
  def update_project_group(%ProjectGroup{} = group, attrs) do
    group
    |> ProjectGroup.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_project_group(ProjectGroup.t()) ::
          {:ok, ProjectGroup.t()} | {:error, Ecto.Changeset.t()}
  def delete_project_group(%ProjectGroup{} = group), do: Repo.delete(group)

  @spec change_project_group(ProjectGroup.t(), map()) :: Ecto.Changeset.t()
  def change_project_group(%ProjectGroup{} = group, attrs \\ %{}) do
    ProjectGroup.changeset(group, attrs)
  end

  # ── Projects ──────────────────────────────────────────────────────────────

  @spec list_projects() :: [Project.t()]
  def list_projects do
    Project
    |> order_by([p], [
      fragment(
        "CASE status WHEN ? THEN 0 WHEN ? THEN 1 WHEN ? THEN 2 WHEN ? THEN 3 ELSE 4 END",
        ^to_string(:active),
        ^to_string(:idea),
        ^to_string(:paused),
        ^to_string(:done)
      ),
      asc: p.name
    ])
    |> Repo.all()
    |> preload_pinned_tasks()
  end

  @type grouped_projects :: [{ProjectGroup.t() | nil, [Project.t()]}]

  @spec list_projects_grouped() :: grouped_projects()
  def list_projects_grouped do
    groups = list_project_groups()

    projects =
      Project
      |> order_by([p], [
        fragment(
          "CASE status WHEN ? THEN 0 WHEN ? THEN 1 WHEN ? THEN 2 WHEN ? THEN 3 ELSE 4 END",
          ^to_string(:active),
          ^to_string(:idea),
          ^to_string(:paused),
          ^to_string(:done)
        ),
        asc: p.name
      ])
      |> Repo.all()
      |> preload_pinned_tasks()

    by_group = Enum.group_by(projects, & &1.project_group_id)

    grouped =
      Enum.flat_map(groups, fn group ->
        group_projects = Map.get(by_group, group.id, [])
        [{group, group_projects}]
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
    |> where([p], p.status == ^status)
    |> order_by([p], asc: p.name)
    |> Repo.all()
    |> preload_pinned_tasks()
  end

  @spec get_project!(project_id()) :: Project.t()
  def get_project!(id), do: Repo.get!(Project, id)

  @spec create_project(map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_project(Project.t(), map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_project(Project.t()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @spec change_project(Project.t(), map()) :: Ecto.Changeset.t()
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @spec count_by_status() :: status_counts()
  def count_by_status do
    Project
    |> group_by([p], p.status)
    |> select([p], {p.status, count(p.id)})
    |> Repo.all()
    |> Map.new()
  end

  @spec preload_pinned_tasks([Project.t()]) :: [Project.t()]
  defp preload_pinned_tasks(projects) do
    project_ids = Enum.map(projects, & &1.id)

    if project_ids == [] do
      Enum.map(projects, &%{&1 | pinned_tasks: %{current: nil, upcoming: nil}})
    else
      pinned_tasks =
        Task
        |> where([t], t.project_id in ^project_ids and t.pin_status in ^[:current, :upcoming])
        |> Repo.all()
        |> Enum.group_by(& &1.project_id)

      Enum.map(projects, fn project ->
        tasks = Map.get(pinned_tasks, project.id, [])

        current = Enum.find(tasks, &(&1.pin_status == :current))
        upcoming = Enum.find(tasks, &(&1.pin_status == :upcoming))

        %{project | pinned_tasks: %{current: current, upcoming: upcoming}}
      end)
    end
  end

  # ── Tasks ─────────────────────────────────────────────────────────────────

  @spec list_tasks(project_id()) :: [Task.t()]
  def list_tasks(project_id) do
    Task
    |> where([t], t.project_id == ^project_id)
    |> order_by([t],
      asc:
        fragment(
          "CASE ? WHEN ? THEN 0 WHEN ? THEN 1 ELSE 2 END",
          t.pin_status,
          ^to_string(:current),
          ^to_string(:upcoming)
        ),
      asc: t.sort_order,
      asc: t.inserted_at
    )
    |> Repo.all()
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
      [%{task | subtasks: children} | Enum.map(children, &%{&1 | subtasks: []})]
    end)
  end

  @spec list_tasks_tree(project_id()) :: [{Task.t(), [Task.t()]}]
  def list_tasks_tree(project_id) do
    tasks = list_tasks(project_id)

    groups =
      tasks
      |> Enum.group_by(& &1.parent_task_id)

    parents = Map.get(groups, nil, [])

    Enum.map(parents, fn parent ->
      {parent, Map.get(groups, parent.id, [])}
    end)
  end

  @spec list_subtasks(task_id()) :: [Task.t()]
  def list_subtasks(task_id) do
    Task
    |> where([t], t.parent_task_id == type(^task_id, :binary_id))
    |> order_by([t], asc: t.sort_order, asc: t.inserted_at)
    |> Repo.all()
  end

  @spec toggle_task_done(task_id() | Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def toggle_task_done(id) when is_binary(id) do
    id
    |> get_task!()
    |> toggle_task_done()
  end

  def toggle_task_done(%Task{} = task) do
    set_task_done(task, task.status != :done)
  end

  @spec set_task_done(Task.t(), boolean()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def set_task_done(%Task{} = task, done?) when is_boolean(done?) do
    new_status = if done?, do: :done, else: :todo

    Repo.transaction(fn ->
      {:ok, task} = update_task(task, %{status: new_status})

      if task.parent_task_id == nil do
        cascade_task_status(task, new_status)
      end

      update_task_ancestors(task)

      get_task!(task.id)
    end)
    |> case do
      {:ok, updated} ->
        {:ok, updated}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp cascade_task_status(%Task{} = task, status) when status in [:done, :todo] do
    task_id = task.id

    Repo.update_all(from(t in Task, where: t.parent_task_id == type(^task_id, :binary_id)),
      set: [status: status, pin_status: nil]
    )

    subtasks = list_subtasks(task_id)
    Enum.each(subtasks, &cascade_task_status(&1, status))
  end

  defp update_task_ancestors(%Task{} = task) do
    case task.parent_task_id do
      nil ->
        :ok

      parent_id ->
        parent = get_task!(parent_id)
        children = list_subtasks(parent.id)
        all_done? = children != [] and Enum.all?(children, &(&1.status == :done))
        desired = if all_done?, do: :done, else: :todo

        if parent.status != desired do
          {:ok, parent} = update_task(parent, %{status: desired, pin_status: nil})
          update_task_ancestors(parent)
        else
          :ok
        end
    end
  end

  @spec pin_task(task_id(), :current | :upcoming) ::
          {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def pin_task(id, pin_status) when pin_status in [:current, :upcoming] do
    task = get_task!(id)

    case task.status do
      :done ->
        {:error,
         Ecto.Changeset.change(task)
         |> Ecto.Changeset.add_error(:pin_status, "cannot pin a done task")}

      _ ->
        update_task(task, %{pin_status: pin_status})
    end
  end

  @spec unpin_task(task_id()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def unpin_task(id) do
    task = get_task!(id)
    update_task(task, %{pin_status: nil})
  end

  @spec get_task!(task_id()) :: Task.t()
  def get_task!(id), do: Repo.get!(Task, id)

  @spec create_task(map()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def create_task(attrs) do
    attrs = maybe_put_next_task_sort_order(attrs)
    attrs = maybe_clear_pin_status_for_done(attrs)

    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @spec maybe_put_next_task_sort_order(map()) :: map()
  defp maybe_put_next_task_sort_order(%{"project_id" => project_id} = attrs) do
    max_order =
      Task
      |> where([t], t.project_id == ^project_id)
      |> select([t], max(t.sort_order))
      |> Repo.one()

    next = (max_order || 0) + 1
    Map.put(attrs, "sort_order", next)
  end

  defp maybe_put_next_task_sort_order(attrs), do: attrs

  @spec maybe_clear_pin_status_for_done(map()) :: map()
  defp maybe_clear_pin_status_for_done(%{"status" => status} = attrs)
       when status in ["done", :done],
       do: Map.put(attrs, "pin_status", nil)

  defp maybe_clear_pin_status_for_done(%{status: :done} = attrs),
    do: Map.put(attrs, :pin_status, nil)

  defp maybe_clear_pin_status_for_done(attrs), do: attrs

  @spec unpin_other_tasks(project_id(), String.t() | atom(), task_id()) ::
          {non_neg_integer(), nil | [term()]}
  defp unpin_other_tasks(project_id, pin_status, keep_task_id) do
    pin_status = if is_atom(pin_status), do: to_string(pin_status), else: pin_status

    Repo.update_all(
      from(t in Task,
        where:
          t.project_id == ^project_id and t.pin_status == ^pin_status and t.id != ^keep_task_id
      ),
      set: [pin_status: nil]
    )
  end

  @spec update_task(Task.t(), map()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def update_task(%Task{} = task, attrs) do
    attrs = maybe_clear_pin_status_for_done(attrs)
    project_id = task.project_id

    Repo.transaction(fn ->
      if Map.get(attrs, :pin_status) in [:current, :upcoming] or
           Map.get(attrs, "pin_status") in ["current", "upcoming"] do
        pin_status = Map.get(attrs, :pin_status) || Map.get(attrs, "pin_status")
        unpin_other_tasks(project_id, pin_status, task.id)
      end

      task
      |> Task.changeset(attrs)
      |> Repo.update()
    end)
    |> case do
      {:ok, {:ok, updated_task}} ->
        {:ok, updated_task}

      {:ok, {:error, changeset}} ->
        {:error, changeset}

      {:error, reason} ->
        {:error, Ecto.Changeset.change(task) |> Ecto.Changeset.add_error(:base, inspect(reason))}
    end
  end

  @spec delete_task(Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def delete_task(%Task{} = task), do: Repo.delete(task)

  @spec change_task(Task.t(), map()) :: Ecto.Changeset.t()
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  @spec task_stats(project_id()) :: task_stats()
  def task_stats(project_id) do
    Task
    |> where([t], t.project_id == ^project_id)
    |> group_by([t], t.status)
    |> select([t], {t.status, count(t.id)})
    |> Repo.all()
    |> Map.new()
  end

  @spec reorder_tasks(project_id(), [Ecto.UUID.t()]) :: :ok
  def reorder_tasks(project_id, ordered_ids) when is_list(ordered_ids) do
    Repo.transaction(fn ->
      ordered_ids
      |> Enum.with_index(1)
      |> Enum.each(fn {id, sort_order} ->
        Repo.update_all(
          from(t in Task, where: t.project_id == ^project_id and t.id == ^id),
          set: [sort_order: sort_order]
        )
      end)
    end)

    :ok
  end

  @spec reorder_subtasks(Ecto.UUID.t(), [Ecto.UUID.t()]) :: :ok
  def reorder_subtasks(parent_task_id, ordered_ids) when is_list(ordered_ids) do
    Repo.transaction(fn ->
      ordered_ids
      |> Enum.with_index(1)
      |> Enum.each(fn {id, sort_order} ->
        Repo.update_all(
          from(t in Task,
            where:
              t.parent_task_id == type(^parent_task_id, :binary_id) and
                t.id == type(^id, :binary_id)
          ),
          set: [sort_order: sort_order]
        )
      end)
    end)

    :ok
  end

  # ── BOM Items ─────────────────────────────────────────────────────────────

  @spec list_bom_items(project_id()) :: [BomItem.t()]
  def list_bom_items(project_id) do
    BomItem
    |> where([b], b.project_id == ^project_id)
    |> order_by([b], asc: b.sort_order, asc: b.inserted_at)
    |> Repo.all()
  end

  @spec get_bom_item!(bom_item_id()) :: BomItem.t()
  def get_bom_item!(id), do: Repo.get!(BomItem, id)

  @spec create_bom_item(map()) :: {:ok, BomItem.t()} | {:error, Ecto.Changeset.t()}
  def create_bom_item(attrs) do
    %BomItem{}
    |> BomItem.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_bom_item(BomItem.t(), map()) :: {:ok, BomItem.t()} | {:error, Ecto.Changeset.t()}
  def update_bom_item(%BomItem{} = item, attrs) do
    item
    |> BomItem.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_bom_item(BomItem.t()) :: {:ok, BomItem.t()} | {:error, Ecto.Changeset.t()}
  def delete_bom_item(%BomItem{} = item), do: Repo.delete(item)

  @spec change_bom_item(BomItem.t(), map()) :: Ecto.Changeset.t()
  def change_bom_item(%BomItem{} = item, attrs \\ %{}) do
    BomItem.changeset(item, attrs)
  end

  @spec bom_budget(project_id()) :: bom_budget()
  def bom_budget(project_id) do
    items = list_bom_items(project_id)

    total =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        price = item.unit_price || Decimal.new(0)
        qty = Decimal.new(item.quantity)
        Decimal.add(acc, Decimal.mult(price, qty))
      end)

    spent =
      items
      |> Enum.filter(&(&1.status in [:ordered, :received]))
      |> Enum.reduce(Decimal.new(0), fn item, acc ->
        price = item.unit_price || Decimal.new(0)
        qty = Decimal.new(item.quantity)
        Decimal.add(acc, Decimal.mult(price, qty))
      end)

    %{total: total, spent: spent, items: items}
  end

  # ── Journal Entries ───────────────────────────────────────────────────────

  @spec list_journal_entries(project_id()) :: [JournalEntry.t()]
  def list_journal_entries(project_id) do
    JournalEntry
    |> where([j], j.project_id == ^project_id)
    |> order_by([j], desc: j.sort_order, desc: j.inserted_at)
    |> Repo.all()
  end

  @spec list_journal_entries_page(project_id(), pos_integer(), pos_integer()) ::
          [JournalEntry.t()]
  def list_journal_entries_page(project_id, page, per_page) do
    offset = (page - 1) * per_page

    JournalEntry
    |> where([j], j.project_id == ^project_id)
    |> order_by([j], desc: j.sort_order, desc: j.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  @spec count_journal_entries(project_id()) :: non_neg_integer()
  def count_journal_entries(project_id) do
    JournalEntry
    |> where([j], j.project_id == ^project_id)
    |> Repo.aggregate(:count)
  end

  @spec get_journal_entry!(journal_entry_id()) :: JournalEntry.t()
  def get_journal_entry!(id), do: Repo.get!(JournalEntry, id)

  @spec create_journal_entry(map()) ::
          {:ok, JournalEntry.t()} | {:error, Ecto.Changeset.t()}
  def create_journal_entry(attrs) do
    attrs = maybe_put_next_journal_sort_order(attrs)

    %JournalEntry{}
    |> JournalEntry.changeset(attrs)
    |> Repo.insert()
  end

  @spec maybe_put_next_journal_sort_order(map()) :: map()
  defp maybe_put_next_journal_sort_order(%{"project_id" => project_id} = attrs) do
    max_order =
      JournalEntry
      |> where([j], j.project_id == ^project_id)
      |> select([j], max(j.sort_order))
      |> Repo.one()

    next = (max_order || 0) + 1
    Map.put(attrs, "sort_order", next)
  end

  defp maybe_put_next_journal_sort_order(attrs), do: attrs

  @spec update_journal_entry(JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()} | {:error, Ecto.Changeset.t()}
  def update_journal_entry(%JournalEntry{} = entry, attrs) do
    entry
    |> JournalEntry.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_journal_entry(JournalEntry.t()) ::
          {:ok, JournalEntry.t()} | {:error, Ecto.Changeset.t()}
  def delete_journal_entry(%JournalEntry{} = entry), do: Repo.delete(entry)

  @spec change_journal_entry(JournalEntry.t(), map()) :: Ecto.Changeset.t()
  def change_journal_entry(%JournalEntry{} = entry, attrs \\ %{}) do
    JournalEntry.changeset(entry, attrs)
  end
end
