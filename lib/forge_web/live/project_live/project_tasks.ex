defmodule ForgeWeb.ProjectLive.Tasks do
  use Phoenix.Component

  alias Forge.Projects
  alias Forge.Projects.Task

  alias ForgeWeb.ProjectLive.Result

  @type project_id :: Projects.project_id()

  defdelegate list_tasks(project_id), to: Projects, as: :list_tasks
  defdelegate list_tasks_with_subtasks(project_id), to: Projects, as: :list_tasks_with_subtasks
  defdelegate list_tasks_tree(project_id), to: Projects, as: :list_tasks_tree
  defdelegate create_task(attrs), to: Projects, as: :create_task
  defdelegate toggle_task_done(task), to: Projects, as: :toggle_task_done
  defdelegate delete_task(task), to: Projects, as: :delete_task
  defdelegate update_task(task, attrs), to: Projects, as: :update_task
  defdelegate change_task(task, attrs), to: Projects, as: :change_task
  defdelegate task_stats(project_id), to: Projects, as: :task_stats

  @spec handle_task_update(map(), project_id()) ::
          Result.ok(Task.t())
          | Result.error_changeset()
          | {:error, :blank_title}
  def handle_task_update(%{"task_id" => id, "task" => params}, project_id) do
    task = Projects.get_task!(id)

    title = params |> Map.get("title", "") |> String.trim()

    if title == "" do
      {:error, :blank_title}
    else
      attrs =
        params
        |> Map.take(["title", "description", "status", "priority"])
        |> Map.put("title", title)
        |> Map.reject(fn {_k, v} -> v == "" or is_nil(v) end)

      case update_task(task, attrs) do
        {:ok, _task} ->
          task_counts = task_stats(project_id)
          tasks = list_tasks_with_subtasks(project_id)

          {:ok,
           %{
             assigns: [
               task_counts: task_counts,
               tasks_empty?: tasks == []
             ],
             stream: {:reset, :tasks, tasks}
           }}

        {:error, changeset} ->
          {:error, {:changeset, changeset}}
      end
    end
  end

  @spec handle_task_create(map(), project_id()) ::
          Result.ok(Task.t())
          | Result.error_changeset()
          | {:error, :blank_title}
  def handle_task_create(%{"task" => params} = payload, project_id) do
    title = params |> Map.get("title", "") |> String.trim()

    parent_id =
      payload
      |> Map.get("parent_task_id")
      |> blank_to_nil()

    if title == "" do
      {:error, :blank_title}
    else
      attrs =
        params
        |> Map.take(["title", "description", "status", "priority"])
        |> Map.put("title", title)
        |> Map.reject(fn {_k, v} -> v == "" or is_nil(v) end)
        |> Map.put("project_id", project_id)
        |> maybe_put_parent_task_id(parent_id)

      case create_task(attrs) do
        {:ok, _task} ->
          task_counts = task_stats(project_id)
          tasks = list_tasks_with_subtasks(project_id)

          {:ok,
           %{
             assigns: [
               task_counts: task_counts,
               task_form: task_form(),
               tasks_empty?: tasks == []
             ],
             stream: {:reset, :tasks, tasks}
           }}

        {:error, changeset} ->
          {:error, {:changeset, changeset}}
      end
    end
  end

  @spec maybe_put_parent_task_id(map(), String.t() | nil) :: map()
  defp maybe_put_parent_task_id(attrs, nil), do: attrs
  defp maybe_put_parent_task_id(attrs, parent_id), do: Map.put(attrs, "parent_task_id", parent_id)

  @spec blank_to_nil(String.t() | nil) :: String.t() | nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(other), do: other

  @spec handle_task_toggle(map(), project_id()) ::
          Result.ok(Task.t()) | {:error, :could_not_update}
  def handle_task_toggle(%{"id" => id}, project_id) do
    task = Projects.get_task!(id)

    case toggle_task_done(task) do
      {:ok, _task} ->
        task_counts = task_stats(project_id)
        tasks = list_tasks_with_subtasks(project_id)

        {:ok,
         %{
           assigns: [task_counts: task_counts, tasks_empty?: tasks == []],
           stream: {:reset, :tasks, tasks}
         }}

      {:error, _} ->
        {:error, :could_not_update}
    end
  end

  @spec handle_task_delete(map(), project_id()) :: Result.ok(Task.t())
  def handle_task_delete(%{"id" => id}, project_id) do
    task = Projects.get_task!(id)
    {:ok, _} = delete_task(task)

    task_counts = task_stats(project_id)
    tasks = list_tasks(project_id)

    {:ok,
     %{
       assigns: [task_counts: task_counts, tasks_empty?: tasks == []],
       stream_delete: {:tasks, task}
     }}
  end

  @spec task_form() :: Phoenix.HTML.Form.t()
  def task_form do
    AshPhoenix.Form.for_create(Forge.Projects.Task, :create,
      domain: Forge.Projects,
      as: "task"
    )
    |> Phoenix.Component.to_form()
  end
end
