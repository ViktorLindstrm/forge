defmodule ForgeWeb.ProjectLive.TaskHandlers do
  @moduledoc """
  Handles all task-related `handle_event` clauses for `ForgeWeb.ProjectLive.Show`.

  Each function takes `(params, socket)` and returns `{:noreply, socket}`.
  The main LiveView delegates task events here after the `with_tasks_enabled` guard.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [stream: 4, stream_delete: 3, put_flash: 3]

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Tasks

  @type socket :: Phoenix.LiveView.Socket.t()

  @spec task_create(map(), socket()) :: {:noreply, socket()}
  def task_create(%{"task" => params} = payload, socket) do
    project_id = socket.assigns.project.id

    params =
      params
      |> Map.put("project_id", project_id)
      |> maybe_put_parent_task_id(Map.get(payload, "parent_task_id"))

    case AshPhoenix.Form.submit(socket.assigns.task_form.source, params: params) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> reload_tasks()
         |> assign(:task_form, Tasks.task_form())
         |> assign(:task_form_open?, false)
         |> assign(:expanded_task_id, nil)}

      {:error, form} ->
        {:noreply, assign(socket, :task_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec task_toggle(map(), socket()) :: {:noreply, socket()}
  def task_toggle(%{"id" => id}, socket) do
    socket = assign(socket, :expanded_task_id, nil)
    task = Projects.get_task!(id)

    case Projects.toggle_task_done(task) do
      {:ok, _task} -> {:noreply, reload_tasks(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not update task.")}
    end
  end

  @spec task_delete(map(), socket()) :: {:noreply, socket()}
  def task_delete(%{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    socket = assign(socket, :expanded_task_id, nil)
    task = Projects.get_task!(id)
    {:ok, _} = Projects.delete_task(task)
    tasks = Projects.list_tasks_with_subtasks(project_id)

    {:noreply,
     socket
     |> assign(:task_counts, Projects.task_stats(project_id))
     |> assign(:tasks_empty?, tasks == [])
     |> stream_delete(:tasks, task)}
  end

  @spec task_edit_open(map(), socket()) :: {:noreply, socket()}
  def task_edit_open(%{"id" => id}, socket) do
    task = Projects.get_task!(id)
    form = Tasks.task_edit_form(task)
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:expanded_task_id, nil)
     |> assign(:editing_task_id, task.id)
     |> assign(:task_edit_form, form)
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec task_edit_cancel(map(), socket()) :: {:noreply, socket()}
  def task_edit_cancel(_params, socket) do
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:editing_task_id, nil)
     |> assign(:task_edit_form, Tasks.task_form())
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec task_edit_validate(map(), socket()) :: {:noreply, socket()}
  def task_edit_validate(%{"task" => task_params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.task_edit_form.source, task_params)
      |> Phoenix.Component.to_form()

    {:noreply, assign(socket, :task_edit_form, form)}
  end

  @spec task_edit_save(map(), socket()) :: {:noreply, socket()}
  def task_edit_save(%{"task" => params}, socket) do
    socket = assign(socket, :expanded_task_id, nil)

    case AshPhoenix.Form.submit(socket.assigns.task_edit_form.source, params: params) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> reload_tasks()
         |> assign(:editing_task_id, nil)
         |> assign(:task_edit_form, Tasks.task_form())}

      {:error, form} ->
        {:noreply, assign(socket, :task_edit_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec task_details_toggle(map(), socket()) :: {:noreply, socket()}
  def task_details_toggle(%{"id" => id}, socket) do
    expanded = socket.assigns.expanded_task_id

    new_expanded =
      case expanded do
        ^id -> nil
        _ -> id
      end

    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:expanded_task_id, new_expanded)
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec task_pin_cycle(map(), socket()) :: {:noreply, socket()}
  def task_pin_cycle(%{"id" => id}, socket) do
    task = Projects.get_task!(id)
    socket = assign(socket, :expanded_task_id, nil)

    case Projects.cycle_task_pin(task) do
      {:ok, _task} -> {:noreply, reload_tasks(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not update pin status.")}
    end
  end

  @spec task_pin(map(), socket()) :: {:noreply, socket()}
  def task_pin(%{"id" => id, "pin_status" => pin_status}, socket)
      when pin_status in ["current", "upcoming"] do
    socket = assign(socket, :expanded_task_id, nil)

    case Projects.pin_task(id, String.to_existing_atom(pin_status)) do
      {:ok, _task} -> {:noreply, reload_tasks(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not pin task.")}
    end
  end

  @spec task_unpin(map(), socket()) :: {:noreply, socket()}
  def task_unpin(%{"id" => id}, socket) do
    socket = assign(socket, :expanded_task_id, nil)

    case Projects.unpin_task(id) do
      {:ok, _task} -> {:noreply, reload_tasks(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not unpin task.")}
    end
  end

  @spec tasks_reorder(map(), socket()) :: {:noreply, socket()}
  def tasks_reorder(%{"ids" => ids}, socket) do
    project_id = socket.assigns.project.id
    :ok = Projects.reorder_tasks(project_id, ids)
    tasks = Projects.list_tasks_with_subtasks(project_id)

    {:noreply,
     socket
     |> assign(:expanded_task_id, nil)
     |> assign(:editing_task_id, nil)
     |> assign(:subtask_form_task_id, nil)
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec subtasks_reorder(map(), socket()) :: {:noreply, socket()}
  def subtasks_reorder(%{"parent_id" => parent_id, "ids" => ids}, socket) do
    project_id = socket.assigns.project.id
    :ok = Projects.reorder_subtasks(parent_id, ids)
    tasks = Projects.list_tasks_with_subtasks(project_id)
    {:noreply, stream(socket, :tasks, tasks, reset: true)}
  end

  @spec subtask_form_open(map(), socket()) :: {:noreply, socket()}
  def subtask_form_open(%{"id" => id}, socket) do
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:subtask_form_task_id, id)
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec subtask_form_close(map(), socket()) :: {:noreply, socket()}
  def subtask_form_close(%{"id" => id}, socket) do
    current_id = to_string(socket.assigns.subtask_form_task_id)

    new_value =
      case current_id do
        ^id -> nil
        _ -> socket.assigns.subtask_form_task_id
      end

    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:subtask_form_task_id, new_value)
     |> stream(:tasks, tasks, reset: true)}
  end

  @spec subtasks_toggle(map(), socket()) :: {:noreply, socket()}
  def subtasks_toggle(%{"id" => id}, socket) do
    id = to_string(id)
    set = socket.assigns.collapsed_subtasks

    new_set =
      case MapSet.member?(set, id) do
        true -> MapSet.delete(set, id)
        false -> MapSet.put(set, id)
      end

    {:noreply, assign(socket, :collapsed_subtasks, new_set)}
  end

  @spec toggle_task_form(map(), socket()) :: {:noreply, socket()}
  def toggle_task_form(_params, socket) do
    {:noreply, assign(socket, :task_form_open?, !socket.assigns.task_form_open?)}
  end

  @spec reload_tasks(socket()) :: socket()
  def reload_tasks(socket) do
    project_id = socket.assigns.project.id
    tasks = Projects.list_tasks_with_subtasks(project_id)

    socket
    |> assign(:task_counts, Projects.task_stats(project_id))
    |> assign(:tasks_empty?, tasks == [])
    |> stream(:tasks, tasks, reset: true)
  end

  @spec maybe_put_parent_task_id(map(), String.t() | nil | binary()) :: map()
  defp maybe_put_parent_task_id(params, nil), do: params
  defp maybe_put_parent_task_id(params, ""), do: params

  defp maybe_put_parent_task_id(params, parent_id),
    do: Map.put(params, "parent_task_id", parent_id)
end
