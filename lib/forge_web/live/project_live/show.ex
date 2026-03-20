defmodule ForgeWeb.ProjectLive.Show do
  use ForgeWeb, :live_view

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Components

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

        <div class="flex items-center gap-2">
          <.link
            navigate={~p"/projects/#{@project}/edit?return_to=show"}
            class="inline-flex items-center gap-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
            id="project-edit"
          >
            <.icon name="hero-pencil" class="size-3.5 text-gray-400" /> Edit
          </.link>

          <button
            class="inline-flex items-center justify-center rounded-xl bg-red-50 dark:bg-red-950/40 px-3 py-2 text-sm font-medium text-red-700 dark:text-red-300 hover:bg-red-100 dark:hover:bg-red-950/60 transition-colors"
            phx-click="delete"
            data-confirm="Delete this project?"
            id="project-delete"
          >
            Delete
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
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <Components.stats_grid task_counts={@task_counts} />

          <Components.tasks_component
            task_counts={@task_counts}
            task_form={@task_form}
            streams={@streams}
            tasks_empty?={@tasks_empty?}
            sections_open={@sections_open}
            bom_budget={@bom_budget}
            bom_form={@bom_form}
            journal_entries={@journal_entries}
            journal_form={@journal_form}
            editing_journal_entry_id={@editing_journal_entry_id}
            journal_edit_form={@journal_edit_form}
          />
        </div>

        <div class="space-y-6">
          <Components.bom_component bom_budget={@bom_budget} bom_form={@bom_form} />
          <Components.journal_component journal_entries={@journal_entries} journal_form={@journal_form} editing_journal_entry_id={@editing_journal_entry_id} journal_edit_form={@journal_edit_form} />

          <div
            class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6"
            id="project-notes"
          >
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <.icon name="hero-document-text" class="size-4 text-gray-400" /> Notes
              </h2>
              <.link
                navigate={~p"/projects/#{@project}/edit?return_to=show"}
                class="text-xs text-violet-600 dark:text-violet-400 hover:underline"
                id="project-notes-edit"
              >
                Edit
              </.link>
            </div>

            <%= if @project.notes && @project.notes != "" do %>
              <div class="prose prose-sm dark:prose-invert max-w-none">
                <p class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap leading-relaxed">
                  {@project.notes}
                </p>
              </div>
            <% else %>
              <p class="text-sm text-gray-400 dark:text-gray-600 italic">
                No notes yet.
              </p>
            <% end %>
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

    tasks = Projects.list_tasks(project.id)

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:page_title, "Project · Forge")
     |> assign(:sections_open, %{tasks: true})
     |> assign(:task_counts, task_counts)
     |> assign(:task_form, to_form(%{"title" => ""}, as: :task))
     |> assign(:bom_budget, Projects.bom_budget(project.id))
     |> assign(:bom_form, to_form(Components.bom_params(), as: :bom))
     |> assign(:journal_entries, Projects.list_journal_entries(project.id))
     |> assign(:journal_form, to_form(Components.journal_params(), as: :journal))
     |> assign(:editing_journal_entry_id, nil)
     |> assign(:journal_edit_form, to_form(Components.journal_params(), as: :journal_edit))
     |> assign(:tasks_empty?, tasks == [])
     |> stream(:tasks, tasks)}
  end

  @impl true
  def handle_info({:project_updated, project}, socket) do
    {:noreply, assign(socket, :project, project)}
  end

  def handle_event("task_create", params, socket) do
    case ForgeWeb.ProjectLive.Tasks.handle_task_create(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns, stream: {:reset, stream_name, items}}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, stream(socket, stream_name, items, reset: true)}

      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      {:error, {:changeset, changeset}} ->
        {:noreply, assign(socket, :task_form, to_form(changeset, as: :task))}

      {:error, :blank_title} ->
        {:noreply, socket}
    end
  end

  def handle_event("task_toggle", params, socket) do
    case ForgeWeb.ProjectLive.Tasks.handle_task_toggle(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns, stream: {:reset, stream_name, items}}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, stream(socket, stream_name, items, reset: true)}

      {:error, :could_not_update} ->
        {:noreply, put_flash(socket, :error, "Could not update task.")}
    end
  end

  def handle_event("task_delete", params, socket) do
    case ForgeWeb.ProjectLive.Tasks.handle_task_delete(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns, stream_delete: {stream_name, item}}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, stream_delete(socket, stream_name, item)}

      _ ->
        {:noreply, socket}
    end
  end


  def handle_event("bom_create", params, socket) do
    case ForgeWeb.ProjectLive.Bom.handle_bom_create(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      {:error, {:changeset, changeset}} ->
        {:noreply, assign(socket, :bom_form, to_form(changeset, as: :bom))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("bom_delete", params, socket) do
    case ForgeWeb.ProjectLive.Bom.handle_bom_delete(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("bom_toggle", params, socket) do
    case ForgeWeb.ProjectLive.Bom.handle_bom_toggle(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      {:error, :could_not_update} ->
        {:noreply, put_flash(socket, :error, "Could not update BOM item.")}
    end
  end

  def handle_event("journal_create", params, socket) do
    case ForgeWeb.ProjectLive.Journal.handle_journal_create(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      {:error, {:changeset, changeset}} ->
        {:noreply, assign(socket, :journal_form, to_form(changeset, as: :journal))}

      {:error, :blank_body} ->
        {:noreply, socket}
    end
  end

  def handle_event("journal_edit", params, socket) do
    case ForgeWeb.ProjectLive.Journal.handle_journal_edit(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("journal_cancel_edit", _params, socket) do
    case ForgeWeb.ProjectLive.Journal.handle_journal_cancel_edit(%{}, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("journal_save_edit", params, socket) do
    case ForgeWeb.ProjectLive.Journal.handle_journal_save_edit(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      {:error, {:changeset, changeset, entry_id}} ->
        {:noreply, assign(socket, :journal_edit_form, to_form(changeset, as: :journal_edit))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("journal_delete", params, socket) do
    case ForgeWeb.ProjectLive.Journal.handle_journal_delete(params, socket.assigns.project.id) do
      {:ok, %{assigns: assigns}} ->
        socket = Enum.reduce(assigns, socket, fn {k, v}, acc -> assign(acc, k, v) end)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end
  def handle_event("toggle_section", %{"section" => "tasks"}, socket) do
    open = !socket.assigns.sections_open.tasks
    socket = assign(socket, :sections_open, %{socket.assigns.sections_open | tasks: open})

    if open do
      tasks = Projects.list_tasks(socket.assigns.project.id)

      {:noreply,
       socket
       |> assign(:tasks_empty?, tasks == [])
       |> stream(:tasks, tasks, reset: true)}
    else
      {:noreply, socket}
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
end
