defmodule ForgeWeb.ProjectLive.Show do
  use ForgeWeb, :live_view

  alias Ash.Notifier.Notification
  alias Forge.Projects
  alias ForgeWeb.ProjectLive.BomHandlers
  alias ForgeWeb.ProjectLive.Budget
  alias ForgeWeb.ProjectLive.Components
  alias ForgeWeb.ProjectLive.Bom
  alias ForgeWeb.ProjectLive.NoteHandlers
  alias ForgeWeb.ProjectLive.Notes
  alias ForgeWeb.ProjectLive.TaskHandlers
  alias ForgeWeb.ProjectLive.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mb-6">
        <.link
          navigate={~p"/projects"}
          class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
          id="projects-back"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Projects
        </.link>
      </div>

      <Components.project_header
        project={@project}
        budget_editing?={@budget_editing?}
        budget_form={@budget_form}
      />

      <div class="space-y-6">
        <Components.summary_grid
          task_counts={@task_counts}
          project={@project}
          note_count={@note_count}
        />

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div :if={@project.tasks_enabled} class="lg:col-span-7 space-y-6">
            <Components.tasks_component
              task_counts={@task_counts}
              task_form={@task_form}
              task_form_open?={@task_form_open?}
              expanded_task_id={@expanded_task_id}
              editing_task_id={@editing_task_id}
              task_edit_form={@task_edit_form}
              streams={@streams}
              tasks_empty?={@tasks_empty?}
              sections_open={@sections_open}
              subtask_form_task_id={@subtask_form_task_id}
              collapsed_subtasks={@collapsed_subtasks}
            />

            <Components.bom_component
              sections_open={@sections_open}
              project={@project}
              bom_budget={@bom_budget}
              bom_form={@bom_form}
              bom_form_open?={@bom_form_open?}
              editing_bom_id={@editing_bom_id}
              bom_edit_form={@bom_edit_form}
              currency={@project.currency}
            />
          </div>

          <div class={[
            "space-y-6",
            if(@project.tasks_enabled, do: "lg:col-span-5", else: "lg:col-span-12")
          ]}>
            <Components.notes_component
              sections_open={@sections_open}
              project={@project}
              note_form={@note_form}
              note_form_open?={@note_form_open?}
              note_preview?={@note_preview?}
              note_preview_body={@note_preview_body}
              streams={@streams}
              notes_empty?={@notes_empty?}
              note_page={@note_page}
              note_total_pages={@note_total_pages}
              editing_note_id={@editing_note_id}
              note_edit_form={@note_edit_form}
            />

            <Components.bom_component
              :if={!@project.tasks_enabled}
              sections_open={@sections_open}
              project={@project}
              bom_budget={@bom_budget}
              bom_form={@bom_form}
              bom_form_open?={@bom_form_open?}
              editing_bom_id={@editing_bom_id}
              bom_edit_form={@bom_edit_form}
              currency={@project.currency}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    project = Projects.get_project!(id)

    subscribe_pubsub(socket, project)

    %{entries: entries, count: note_count} =
      Projects.list_journal_entries_page(project.id, 1, Notes.notes_per_page())

    total_pages = Kernel.max(1, ceil(note_count / Notes.notes_per_page()))

    socket =
      socket
      |> assign(:project, project)
      |> assign(:page_title, "Project · Forge")
      |> assign(:sections_open, %{tasks: true, bom: true, notes: true})
      |> assign(:bom_budget, Projects.bom_budget(project))
      |> assign(:bom_form, Bom.bom_form())
      |> assign(:bom_form_open?, false)
      |> assign(:editing_bom_id, nil)
      |> assign(:bom_edit_form, nil)
      |> assign(:note_form, Notes.note_form())
      |> assign(:note_form_open?, false)
      |> assign(:note_preview?, false)
      |> assign(:note_preview_body, "")
      |> assign(:editing_note_id, nil)
      |> assign(:note_edit_form, nil)
      |> assign(:note_count, note_count)
      |> assign(:note_page, 1)
      |> assign(:note_total_pages, total_pages)
      |> assign(:notes_empty?, entries == [])
      |> assign(:budget_editing?, false)
      |> assign(:budget_form, Budget.budget_form(project))
      |> stream(:journal_entries, entries)
      |> init_task_assigns(project)

    {:ok, socket}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          payload: %Notification{resource: Forge.Projects.Task, action: action, data: task}
        },
        socket
      ) do
    with_tasks_enabled(socket, fn socket -> apply_task_notification(socket, action, task) end)
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          payload: %Notification{resource: Forge.Projects.BomItem}
        },
        socket
      ) do
    {:noreply, BomHandlers.reload_bom(socket)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          payload: %Notification{resource: Forge.Projects.JournalEntry}
        },
        socket
      ) do
    {:noreply, NoteHandlers.reload_notes(socket, socket.assigns.note_page)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          payload: %Notification{resource: Forge.Projects.Project, data: project}
        },
        socket
      ) do
    current = socket.assigns.project
    updated = Projects.get_project!(project.id)
    socket = assign(socket, :project, updated)

    case {current.tasks_enabled, updated.tasks_enabled} do
      {same, same} ->
        {:noreply, socket}

      {_, true} ->
        if connected?(socket),
          do: Phoenix.PubSub.subscribe(Forge.PubSub, "tasks:project:#{updated.id}")

        {:noreply, TaskHandlers.reload_tasks(socket)}

      {_, false} ->
        if connected?(socket),
          do: Phoenix.PubSub.unsubscribe(Forge.PubSub, "tasks:project:#{updated.id}")

        {:noreply,
         socket
         |> assign(:task_counts, %{})
         |> assign(:tasks_empty?, true)
         |> stream(:tasks, [], reset: true)}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # ── Task events ───────────────────────────────────────────────────────────

  @impl true
  def handle_event("task_create", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_create(params, &1))

  def handle_event("task_toggle", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_toggle(params, &1))

  def handle_event("task_delete", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_delete(params, &1))

  def handle_event("task_edit_open", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_edit_open(params, &1))

  def handle_event("task_edit_cancel", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_edit_cancel(params, &1))

  def handle_event("task_edit_validate", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_edit_validate(params, &1))

  def handle_event("task_edit_save", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_edit_save(params, &1))

  def handle_event("task_details_toggle", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_details_toggle(params, &1))

  def handle_event("task_pin_cycle", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_pin_cycle(params, &1))

  def handle_event("task_pin", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_pin(params, &1))

  def handle_event("task_unpin", params, socket),
    do: with_tasks_enabled(socket, &TaskHandlers.task_unpin(params, &1))

  def handle_event("tasks_reorder", params, socket),
    do: TaskHandlers.tasks_reorder(params, socket)

  def handle_event("subtasks_reorder", params, socket),
    do: TaskHandlers.subtasks_reorder(params, socket)

  def handle_event("subtask_form_open", params, socket),
    do: TaskHandlers.subtask_form_open(params, socket)

  def handle_event("subtask_form_close", params, socket),
    do: TaskHandlers.subtask_form_close(params, socket)

  def handle_event("subtasks_toggle", params, socket),
    do: TaskHandlers.subtasks_toggle(params, socket)

  def handle_event("toggle_task_form", params, socket),
    do: TaskHandlers.toggle_task_form(params, socket)

  # ── Note events ───────────────────────────────────────────────────────────

  def handle_event("toggle_note_form", params, socket),
    do: NoteHandlers.toggle_note_form(params, socket)

  def handle_event("note_preview_toggle", params, socket),
    do: NoteHandlers.note_preview_toggle(params, socket)

  def handle_event("note_body_change", params, socket),
    do: NoteHandlers.note_body_change(params, socket)

  def handle_event("note_create", params, socket),
    do: NoteHandlers.note_create(params, socket)

  def handle_event("note_delete", params, socket),
    do: NoteHandlers.note_delete(params, socket)

  def handle_event("note_edit_open", params, socket),
    do: NoteHandlers.note_edit_open(params, socket)

  def handle_event("note_edit_cancel", params, socket),
    do: NoteHandlers.note_edit_cancel(params, socket)

  def handle_event("note_edit_save", params, socket),
    do: NoteHandlers.note_edit_save(params, socket)

  def handle_event("goto-page", params, socket),
    do: NoteHandlers.note_page(params, socket)

  # ── BOM events ────────────────────────────────────────────────────────────

  def handle_event("toggle_bom_form", params, socket),
    do: BomHandlers.toggle_bom_form(params, socket)

  def handle_event("bom_create", params, socket),
    do: BomHandlers.bom_create(params, socket)

  def handle_event("bom_delete", params, socket),
    do: BomHandlers.bom_delete(params, socket)

  def handle_event("bom_toggle", params, socket),
    do: BomHandlers.bom_toggle(params, socket)

  def handle_event("bom_edit_open", params, socket),
    do: BomHandlers.bom_edit_open(params, socket)

  def handle_event("bom_edit_cancel", params, socket),
    do: BomHandlers.bom_edit_cancel(params, socket)

  def handle_event("bom_edit_validate", params, socket),
    do: BomHandlers.bom_edit_validate(params, socket)

  def handle_event("bom_edit_save", params, socket),
    do: BomHandlers.bom_edit_save(params, socket)

  # ── Section + Budget + Delete events ─────────────────────────────────────

  def handle_event("toggle_section", %{"section" => section}, socket)
      when section in ["tasks", "bom", "notes"] do
    section_key = String.to_existing_atom(section)
    open = !socket.assigns.sections_open[section_key]
    socket = assign(socket, :sections_open, %{socket.assigns.sections_open | section_key => open})
    {:noreply, apply_section_open(socket, section_key, open)}
  end

  def handle_event("budget_edit", _params, socket) do
    {:noreply, assign(socket, :budget_editing?, !socket.assigns.budget_editing?)}
  end

  def handle_event("budget_cancel", _params, socket) do
    {:noreply, assign(socket, :budget_editing?, false)}
  end

  def handle_event("budget_update", %{"project" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.budget_form.source, params: params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> reload_project()
         |> assign(:budget_editing?, false)
         |> assign(:budget_form, Budget.budget_form(project))}

      {:error, form} ->
        {:noreply, assign(socket, :budget_form, to_form(form))}
    end
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Projects.delete_project(socket.assigns.project)

    {:noreply,
     socket
     |> put_flash(:info, "Project deleted.")
     |> push_navigate(to: ~p"/projects")}
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  @spec subscribe_pubsub(Phoenix.LiveView.Socket.t(), Forge.Projects.Project.t()) :: :ok
  defp subscribe_pubsub(socket, project) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Forge.PubSub, "projects:project:#{project.id}")
      Phoenix.PubSub.subscribe(Forge.PubSub, "bom_items:project:#{project.id}")
      Phoenix.PubSub.subscribe(Forge.PubSub, "journal_entries:project:#{project.id}")
      subscribe_tasks_pubsub(project)
    end

    :ok
  end

  defp subscribe_tasks_pubsub(%{tasks_enabled: true} = project) do
    Phoenix.PubSub.subscribe(Forge.PubSub, "tasks:project:#{project.id}")
  end

  defp subscribe_tasks_pubsub(_project), do: :ok

  @spec init_task_assigns(Phoenix.LiveView.Socket.t(), Forge.Projects.Project.t()) ::
          Phoenix.LiveView.Socket.t()
  defp init_task_assigns(socket, project) do
    {tasks, task_counts} =
      case project.tasks_enabled do
        true ->
          tasks = Projects.list_tasks_with_subtasks(project.id)
          {tasks, Projects.task_stats(project.id)}

        false ->
          {[], %{}}
      end

    socket
    |> assign(:task_counts, task_counts)
    |> assign(:task_form, Tasks.task_form())
    |> assign(:task_form_open?, false)
    |> assign(:tasks_empty?, tasks == [])
    |> assign(:expanded_task_id, nil)
    |> assign(:editing_task_id, nil)
    |> assign(:task_edit_form, Tasks.task_form())
    |> assign(:subtask_form_task_id, nil)
    |> assign(:collapsed_subtasks, MapSet.new())
    |> stream(:tasks, tasks)
  end

  @spec apply_section_open(Phoenix.LiveView.Socket.t(), atom(), boolean()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_section_open(socket, :tasks, true) do
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    socket
    |> assign(:tasks_empty?, tasks == [])
    |> stream(:tasks, tasks, reset: true)
  end

  defp apply_section_open(socket, :notes, true),
    do: NoteHandlers.reload_notes(socket, socket.assigns.note_page)

  defp apply_section_open(socket, _section, _open), do: socket

  @spec reload_project(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp reload_project(socket) do
    assign(socket, :project, Projects.get_project!(socket.assigns.project.id))
  end

  @spec with_tasks_enabled(
          Phoenix.LiveView.Socket.t(),
          (Phoenix.LiveView.Socket.t() -> {:noreply, Phoenix.LiveView.Socket.t()})
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp with_tasks_enabled(socket, fun) do
    case socket.assigns.project.tasks_enabled do
      true -> fun.(socket)
      false -> {:noreply, socket}
    end
  end

  @spec apply_task_notification(
          Phoenix.LiveView.Socket.t(),
          Ash.Resource.Actions.action(),
          Forge.Projects.Task.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp apply_task_notification(socket, %{type: :destroy}, task) do
    {:noreply,
     socket
     |> stream_delete(:tasks, task)
     |> assign(:task_counts, Projects.task_stats(socket.assigns.project.id))}
  end

  defp apply_task_notification(socket, %{type: _type, touched_attributes: touched}, task) do
    ordering_affected? =
      not MapSet.disjoint?(touched, MapSet.new([:pin_status, :sort_order, :parent_task_id]))

    case ordering_affected? do
      true ->
        {:noreply, TaskHandlers.reload_tasks(socket)}

      false ->
        refreshed = Projects.get_task_with_subtasks!(task.id)

        {:noreply,
         socket
         |> stream_insert(:tasks, refreshed)
         |> assign(:task_counts, Projects.task_stats(socket.assigns.project.id))}
    end
  end

  defp apply_task_notification(socket, _action, _task) do
    {:noreply, TaskHandlers.reload_tasks(socket)}
  end
end
