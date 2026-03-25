defmodule ForgeWeb.ProjectLive.Show do
  use ForgeWeb, :live_view

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Components

  @notes_per_page 3

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex items-center justify-between mb-6">
        <.link
          navigate={~p"/projects"}
          class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
          id="projects-back"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Projects
        </.link>

        <div class="flex items-center gap-1">
          <.link
            navigate={~p"/projects/#{@project}/edit?return_to=show"}
            class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            id="project-edit"
            title="Edit project"
          >
            <.icon name="hero-pencil" class="size-4" />
          </.link>

          <button
            class="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors"
            phx-click="delete"
            data-confirm="Delete this project?"
            id="project-delete"
            title="Delete project"
          >
            <.icon name="hero-trash" class="size-4" />
          </button>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 overflow-hidden mb-6">
        <div class={["h-2", Components.color_bg(@project.color)]} />
        <div class="p-6">
          <div class="flex items-start justify-between gap-4 mb-3">
            <h1
              class="text-2xl font-bold text-gray-900 dark:text-white leading-tight"
              id="project-title"
            >
              {@project.name}
            </h1>
            <Components.status_badge status={@project.status} />
          </div>

          <div :if={@pinned_current_task || @pinned_upcoming_task} class="mb-4" id="project-pins">
            <div
              :if={@pinned_current_task}
              class="flex items-center justify-between gap-3 rounded-xl bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-100 dark:border-emerald-900/40 px-3 py-2"
              id="project-current-task"
            >
              <div class="min-w-0">
                <p class="text-[11px] font-semibold uppercase tracking-wide text-emerald-700 dark:text-emerald-300">
                  Current
                </p>
                <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {@pinned_current_task.title}
                </p>
              </div>
              <button
                type="button"
                phx-click="task_unpin"
                phx-value-id={@pinned_current_task.id}
                class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-emerald-700 dark:text-emerald-200 hover:bg-emerald-100 dark:hover:bg-emerald-900/40 transition-colors"
                id="project-current-unpin"
              >
                Unpin
              </button>
            </div>

            <div
              :if={@pinned_upcoming_task}
              class="mt-2 flex items-center justify-between gap-3 rounded-xl bg-sky-50 dark:bg-sky-900/20 border border-sky-100 dark:border-sky-900/40 px-3 py-2"
              id="project-upcoming-task"
            >
              <div class="min-w-0">
                <p class="text-[11px] font-semibold uppercase tracking-wide text-sky-700 dark:text-sky-300">
                  Upcoming
                </p>
                <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {@pinned_upcoming_task.title}
                </p>
              </div>
              <button
                type="button"
                phx-click="task_unpin"
                phx-value-id={@pinned_upcoming_task.id}
                class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-sky-700 dark:text-sky-200 hover:bg-sky-100 dark:hover:bg-sky-900/40 transition-colors"
                id="project-upcoming-unpin"
              >
                Unpin
              </button>
            </div>
          </div>

          <p
            :if={@project.description}
            class="text-gray-600 dark:text-gray-400 leading-relaxed mb-4"
          >
            {@project.description}
          </p>

          <div class="flex flex-wrap gap-4 text-sm">
            <div
              :if={@project.tech_stack}
              class="flex items-center gap-1.5 text-gray-500 dark:text-gray-400"
            >
              <.icon name="hero-code-bracket" class="size-4 text-gray-400" />
              {@project.tech_stack}
            </div>

            <a
              :if={@project.url}
              href={@project.url}
              target="_blank"
              rel="noopener noreferrer"
              class="flex items-center gap-1.5 text-violet-600 dark:text-violet-400 hover:underline"
            >
              <.icon name="hero-arrow-top-right-on-square" class="size-4" />
              {Components.url_display(@project.url)}
            </a>

            <div class="flex items-center gap-1.5 text-gray-400 dark:text-gray-500 text-xs ml-auto">
              Updated {Calendar.strftime(@project.updated_at, "%b %d, %Y")}
            </div>
          </div>

          <%!-- Budget row --%>
          <div class="mt-4 pt-4 border-t border-gray-100 dark:border-gray-800 flex items-center gap-3">
            <.icon name="hero-banknotes" class="size-4 text-emerald-500 shrink-0" />
            <%= if @budget_editing? do %>
              <.form
                for={@budget_form}
                phx-submit="budget_update"
                id="budget-form"
                class="flex items-center gap-2 flex-1"
              >
                <.input field={@budget_form[:budget]} type="number" step="0.01" label="" />
                <button
                  type="submit"
                  id="budget-save"
                  class="text-xs font-semibold text-violet-600 hover:text-violet-500 shrink-0"
                >
                  Save
                </button>
                <button
                  type="button"
                  phx-click="budget_cancel"
                  class="text-xs font-medium text-gray-500 hover:text-gray-900 shrink-0"
                >
                  Cancel
                </button>
              </.form>
            <% else %>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">
                {budget_display(@project.budget)}
              </span>
              <span
                :if={@bom_budget.items != []}
                class="text-xs text-gray-400 dark:text-gray-500"
              >
                {Components.Formatting.money(@bom_budget.spent)} spent
              </span>
              <button
                type="button"
                phx-click="budget_edit"
                id="budget-edit-trigger"
                class="p-1 rounded-lg text-gray-400 hover:text-violet-600 hover:bg-violet-50 dark:hover:bg-violet-950 transition-colors"
                aria-label="Edit budget"
              >
                <.icon name="hero-pencil-square" class="size-3.5" />
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <div class="space-y-6">
        <Components.summary_grid
          task_counts={@task_counts}
          project={@project}
          bom_budget={@bom_budget}
          note_count={@note_count}
        />

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div class="lg:col-span-7 space-y-6">
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
              bom_budget={@bom_budget}
              bom_form={@bom_form}
              bom_form_open?={@bom_form_open?}
            />
          </div>

          <div class="lg:col-span-5 space-y-6">
            <Components.notes_component
              sections_open={@sections_open}
              project={@project}
              note_form={@note_form}
              note_form_open?={@note_form_open?}
              streams={@streams}
              notes_empty?={@notes_empty?}
              note_page={@note_page}
              note_total_pages={@note_total_pages}
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

    task_counts = Projects.task_stats(project.id)
    tasks = Projects.list_tasks_with_subtasks(project.id)
    note_count = Projects.count_journal_entries(project.id)
    entries = Projects.list_journal_entries_page(project.id, 1, @notes_per_page)
    total_pages = max(1, ceil(note_count / @notes_per_page))

    pinned_current_task = Enum.find(tasks, &(&1.pin_status == :current))
    pinned_upcoming_task = Enum.find(tasks, &(&1.pin_status == :upcoming))

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:page_title, "Project · Forge")
     |> assign(:sections_open, %{tasks: true, bom: true, notes: true})
     |> assign(:task_counts, task_counts)
     |> assign(:task_form, ForgeWeb.ProjectLive.Tasks.task_form())
     |> assign(:bom_budget, Projects.bom_budget(project.id))
     |> assign(:bom_form, Components.bom_form())
     |> assign(:tasks_empty?, tasks == [])
     |> assign(:pinned_current_task, pinned_current_task)
     |> assign(:pinned_upcoming_task, pinned_upcoming_task)
     |> assign(:note_form, ForgeWeb.ProjectLive.Notes.note_form())
     |> assign(:note_form_open?, false)
     |> assign(:task_form_open?, false)
     |> assign(:bom_form_open?, false)
     |> assign(:expanded_task_id, nil)
     |> assign(:editing_task_id, nil)
     |> assign(:task_edit_form, ForgeWeb.ProjectLive.Tasks.task_form())
     |> assign(:subtask_form_task_id, nil)
     |> assign(:collapsed_subtasks, MapSet.new())
     |> assign(:note_count, note_count)
     |> assign(:note_page, 1)
     |> assign(:note_total_pages, total_pages)
     |> assign(:notes_empty?, entries == [])
     |> assign(:budget_editing?, false)
     |> assign(:budget_form, build_budget_form(project))
     |> stream(:tasks, tasks)
     |> stream(:journal_entries, entries)}
  end

  def handle_event("task_create", %{"task" => params} = payload, socket) do
    project_id = socket.assigns.project.id

    params =
      params
      |> Map.put("project_id", project_id)
      |> maybe_put_parent_task_id(Map.get(payload, "parent_task_id"))

    case AshPhoenix.Form.submit(socket.assigns.task_form.source, params: params) do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:task_counts, Projects.task_stats(project_id))
         |> assign(:task_form, ForgeWeb.ProjectLive.Tasks.task_form())
         |> assign(:tasks_empty?, tasks == [])
         |> assign(:task_form_open?, false)
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> assign(:expanded_task_id, nil)
         |> stream(:tasks, tasks, reset: true)}

      {:error, form} ->
        {:noreply, assign(socket, :task_form, to_form(form))}
    end
  end

  def handle_event("task_toggle", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    socket = assign(socket, :expanded_task_id, nil)

    task = Projects.get_task!(id)

    case Projects.toggle_task_done(task) do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:task_counts, Projects.task_stats(project_id))
         |> assign(:tasks_empty?, tasks == [])
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> stream(:tasks, tasks, reset: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update task.")}
    end
  end

  def handle_event("task_delete", %{"id" => id}, socket) do
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

  def handle_event("task_edit_open", %{"id" => id}, socket) do
    task = Projects.get_task!(id)
    form = ForgeWeb.ProjectLive.Tasks.task_edit_form(task)
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:expanded_task_id, nil)
     |> assign(:editing_task_id, task.id)
     |> assign(:task_edit_form, form)
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_event("task_edit_cancel", _params, socket) do
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:editing_task_id, nil)
     |> assign(:task_edit_form, ForgeWeb.ProjectLive.Tasks.task_form())
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_event("task_edit_validate", %{"task_id" => _id, "task" => task_params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.task_edit_form.source, task_params) |> to_form()

    {:noreply, assign(socket, :task_edit_form, form)}
  end

  def handle_event("task_edit_save", %{"task" => params}, socket) do
    project_id = socket.assigns.project.id
    socket = assign(socket, :expanded_task_id, nil)

    case AshPhoenix.Form.submit(socket.assigns.task_edit_form.source, params: params) do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:task_counts, Projects.task_stats(project_id))
         |> assign(:tasks_empty?, tasks == [])
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> assign(:editing_task_id, nil)
         |> assign(:task_edit_form, ForgeWeb.ProjectLive.Tasks.task_form())
         |> stream(:tasks, tasks, reset: true)}

      {:error, form} ->
        {:noreply, assign(socket, :task_edit_form, to_form(form))}
    end
  end

  def handle_event("task_details_toggle", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded_task_id
    new_expanded = if(expanded == id, do: nil, else: id)
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:expanded_task_id, new_expanded)
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_event("task_pin_cycle", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    task = Projects.get_task!(id)
    socket = assign(socket, :expanded_task_id, nil)

    result =
      case task.pin_status do
        :current -> Projects.pin_task(id, :upcoming)
        :upcoming -> Projects.unpin_task(id)
        _ -> Projects.pin_task(id, :current)
      end

    case result do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> assign(:tasks_empty?, tasks == [])
         |> stream(:tasks, tasks, reset: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update pin status.")}
    end
  end

  def handle_event("task_pin", %{"id" => id, "pin_status" => pin_status}, socket)
      when pin_status in ["current", "upcoming"] do
    project_id = socket.assigns.project.id

    socket = assign(socket, :expanded_task_id, nil)

    case Projects.pin_task(id, String.to_existing_atom(pin_status)) do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> assign(:tasks_empty?, tasks == [])
         |> stream(:tasks, tasks, reset: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not pin task.")}
    end
  end

  def handle_event("task_unpin", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id

    socket = assign(socket, :expanded_task_id, nil)

    case Projects.unpin_task(id) do
      {:ok, _task} ->
        tasks = Projects.list_tasks_with_subtasks(project_id)

        {:noreply,
         socket
         |> assign(:pinned_current_task, Enum.find(tasks, &(&1.pin_status == :current)))
         |> assign(:pinned_upcoming_task, Enum.find(tasks, &(&1.pin_status == :upcoming)))
         |> assign(:tasks_empty?, tasks == [])
         |> stream(:tasks, tasks, reset: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not unpin task.")}
    end
  end

  def handle_event("tasks_reorder", %{"ids" => ids}, socket) do
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

  def handle_event("subtasks_reorder", %{"parent_id" => parent_id, "ids" => ids}, socket) do
    project_id = socket.assigns.project.id
    :ok = Projects.reorder_subtasks(parent_id, ids)

    tasks = Projects.list_tasks_with_subtasks(project_id)

    {:noreply, stream(socket, :tasks, tasks, reset: true)}
  end

  def handle_event("subtask_form_open", %{"id" => id}, socket) do
    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:subtask_form_task_id, id)
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_event("subtask_form_close", %{"id" => id}, socket) do
    new_value =
      if to_string(socket.assigns.subtask_form_task_id) == to_string(id),
        do: nil,
        else: socket.assigns.subtask_form_task_id

    tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

    {:noreply,
     socket
     |> assign(:subtask_form_task_id, new_value)
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_event("subtasks_toggle", %{"id" => id}, socket) do
    id = to_string(id)
    set = socket.assigns.collapsed_subtasks

    new_set =
      if MapSet.member?(set, id) do
        MapSet.delete(set, id)
      else
        MapSet.put(set, id)
      end

    {:noreply, assign(socket, :collapsed_subtasks, new_set)}
  end

  def handle_event("toggle_note_form", _params, socket) do
    {:noreply, assign(socket, :note_form_open?, !socket.assigns.note_form_open?)}
  end

  def handle_event("toggle_task_form", _params, socket) do
    {:noreply, assign(socket, :task_form_open?, !socket.assigns.task_form_open?)}
  end

  def handle_event("toggle_bom_form", _params, socket) do
    {:noreply, assign(socket, :bom_form_open?, !socket.assigns.bom_form_open?)}
  end

  def handle_event("note_create", %{"note" => params}, socket) do
    project_id = socket.assigns.project.id

    params = Map.put(params, "project_id", project_id)

    case AshPhoenix.Form.submit(socket.assigns.note_form.source, params: params) do
      {:ok, _entry} ->
        note_count = Projects.count_journal_entries(project_id)
        total_pages = max(1, ceil(note_count / @notes_per_page))
        entries = Projects.list_journal_entries_page(project_id, 1, @notes_per_page)

        {:noreply,
         socket
         |> assign(:note_count, note_count)
         |> assign(:note_page, 1)
         |> assign(:note_total_pages, total_pages)
         |> assign(:notes_empty?, entries == [])
         |> assign(:note_form, ForgeWeb.ProjectLive.Notes.note_form())
         |> assign(:note_form_open?, false)
         |> stream(:journal_entries, entries, reset: true)}

      {:error, form} ->
        {:noreply, assign(socket, :note_form, to_form(form))}
    end
  end

  def handle_event("note_delete", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    entry = Projects.get_journal_entry!(id)
    {:ok, _} = Projects.delete_journal_entry(entry)

    note_count = Projects.count_journal_entries(project_id)
    total_pages = max(1, ceil(note_count / @notes_per_page))
    page = min(socket.assigns.note_page, total_pages)
    entries = Projects.list_journal_entries_page(project_id, page, @notes_per_page)

    socket =
      socket
      |> assign(:note_count, note_count)
      |> assign(:note_page, page)
      |> assign(:note_total_pages, total_pages)
      |> assign(:notes_empty?, entries == [])
      |> stream(:journal_entries, entries, reset: true)

    {:noreply, socket}
  end

  def handle_event("note_page", %{"page" => page_str}, socket) do
    project_id = socket.assigns.project.id
    page = String.to_integer(page_str)
    page = page |> max(1) |> min(socket.assigns.note_total_pages)
    entries = Projects.list_journal_entries_page(project_id, page, @notes_per_page)

    socket =
      socket
      |> assign(:note_page, page)
      |> assign(:notes_empty?, entries == [])
      |> stream(:journal_entries, entries, reset: true)

    {:noreply, socket}
  end

  def handle_event("bom_create", %{"bom" => params}, socket) do
    project_id = socket.assigns.project.id
    params = Map.put(params, "project_id", project_id)

    case AshPhoenix.Form.submit(socket.assigns.bom_form.source, params: params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> assign(:bom_budget, Projects.bom_budget(project_id))
         |> assign(:bom_form, Components.bom_form())
         |> assign(:bom_form_open?, false)}

      {:error, form} ->
        {:noreply, assign(socket, :bom_form, to_form(form))}
    end
  end

  def handle_event("bom_delete", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    item = Projects.get_bom_item!(id)
    {:ok, _} = Projects.delete_bom_item(item)

    {:noreply, assign(socket, :bom_budget, Projects.bom_budget(project_id))}
  end

  def handle_event("bom_toggle", %{"id" => id}, socket) do
    project_id = socket.assigns.project.id
    item = Projects.get_bom_item!(id)

    case Projects.toggle_bom_item_status(item) do
      {:ok, _item} ->
        {:noreply, assign(socket, :bom_budget, Projects.bom_budget(project_id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update BOM item.")}
    end
  end

  def handle_event("toggle_section", %{"section" => "tasks"}, socket) do
    open = !socket.assigns.sections_open.tasks
    socket = assign(socket, :sections_open, %{socket.assigns.sections_open | tasks: open})

    if open do
      tasks = Projects.list_tasks_with_subtasks(socket.assigns.project.id)

      {:noreply,
       socket
       |> assign(:tasks_empty?, tasks == [])
       |> stream(:tasks, tasks, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_section", %{"section" => "bom"}, socket) do
    open = !socket.assigns.sections_open.bom
    {:noreply, assign(socket, :sections_open, %{socket.assigns.sections_open | bom: open})}
  end

  def handle_event("toggle_section", %{"section" => "notes"}, socket) do
    open = !socket.assigns.sections_open.notes
    socket = assign(socket, :sections_open, %{socket.assigns.sections_open | notes: open})

    if open do
      project_id = socket.assigns.project.id
      page = socket.assigns.note_page
      entries = Projects.list_journal_entries_page(project_id, page, @notes_per_page)

      {:noreply,
       socket
       |> assign(:notes_empty?, entries == [])
       |> stream(:journal_entries, entries, reset: true)}
    else
      {:noreply, socket}
    end
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
         |> assign(:project, project)
         |> assign(:budget_editing?, false)
         |> assign(:budget_form, build_budget_form(project))}

      {:error, form} ->
        {:noreply, assign(socket, :budget_form, to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Projects.delete_project(socket.assigns.project)

    {:noreply,
     socket
     |> put_flash(:info, "Project deleted.")
     |> push_navigate(to: ~p"/projects")}
  end

  @spec build_budget_form(Forge.Projects.Project.t()) :: Phoenix.HTML.Form.t()
  defp build_budget_form(project) do
    AshPhoenix.Form.for_update(project, :update,
      domain: Forge.Projects,
      as: "project"
    )
    |> to_form()
  end

  @spec maybe_put_parent_task_id(map(), String.t() | nil | binary()) :: map()
  defp maybe_put_parent_task_id(params, nil), do: params
  defp maybe_put_parent_task_id(params, ""), do: params

  defp maybe_put_parent_task_id(params, parent_id),
    do: Map.put(params, "parent_task_id", parent_id)

  @spec budget_display(Decimal.t() | nil) :: String.t()
  defp budget_display(nil), do: "No budget set"
  defp budget_display(%Decimal{} = d), do: "#{Decimal.to_string(d, :normal)} kr"
end
