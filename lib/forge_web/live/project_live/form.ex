defmodule ForgeWeb.ProjectLive.Form do
  use ForgeWeb, :live_view

  alias Forge.Projects

  @colors [
    {"Blue", :blue},
    {"Violet", :violet},
    {"Emerald", :emerald},
    {"Amber", :amber},
    {"Rose", :rose},
    {"Orange", :orange},
    {"Sky", :sky}
  ]

  @statuses [
    {"💡 Idea", :idea},
    {"⚡ Active", :active},
    {"⏸ Paused", :paused},
    {"✅ Done", :done}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto">
        <%!-- Header --%>
        <div class="flex items-center gap-3 mb-8">
          <.link
            navigate={return_path(@return_to, @project)}
            class="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <.icon name="hero-arrow-left" class="size-5" />
          </.link>
          <div>
            <h1 class="text-xl font-bold text-gray-900 dark:text-white">{@page_title}</h1>
            <p class="text-sm text-gray-500 dark:text-gray-400">
              {if @live_action == :new,
                do: "Start tracking a new project",
                else: "Update project details"}
            </p>
          </div>
        </div>

        <%!-- Form card --%>
        <div class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6 space-y-5">
          <%!-- New-group mini-form (must be outside the project form to avoid nesting) --%>
          <form
            :if={@show_new_group}
            phx-submit="create_group"
            class="flex gap-2 items-center"
            id="new-group-form"
          >
            <input
              type="text"
              id="new-group-name"
              name="new_group_name"
              placeholder="New group name"
              autofocus
              class="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
            <button
              type="submit"
              class="px-3 py-2 rounded-lg bg-violet-600 text-white text-sm font-medium hover:bg-violet-500 transition-colors"
            >
              Add
            </button>
            <button
              type="button"
              phx-click="toggle_new_group"
              class="px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 text-sm text-gray-500 hover:text-gray-700 transition-colors"
            >
              Cancel
            </button>
          </form>

          <.form
            for={@form}
            id="project-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-5"
          >
            <%!-- Name --%>
            <.input
              field={@form[:name]}
              type="text"
              label="Project name"
              placeholder="My awesome project"
            />

            <%!-- Description --%>
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description"
              placeholder="What is this project about?"
              rows={3}
            />

            <%!-- Status + Color row --%>
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                options={@statuses}
              />
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                  Color
                </label>
                <div class="flex gap-2 flex-wrap">
                  <%= for {_label, value} <- @colors do %>
                    <label class="cursor-pointer">
                      <input
                        type="radio"
                        name={@form[:color].name}
                        value={value}
                        checked={@form[:color].value == value}
                        class="sr-only peer"
                      />
                      <span class={[
                        "block size-7 rounded-full border-2 transition-all peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-offset-white dark:peer-checked:ring-offset-gray-900",
                        color_dot(to_string(value)),
                        peer_ring(to_string(value))
                      ]} />
                    </label>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Group --%>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                Group
              </label>
              <div class="flex gap-2">
                <div class="flex-1">
                  <.input
                    field={@form[:project_group_id]}
                    type="select"
                    label=""
                    options={[{"No group", ""} | Enum.map(@groups, fn g -> {g.name, g.id} end)]}
                  />
                </div>
                <button
                  type="button"
                  phx-click="toggle_new_group"
                  class="mt-0.5 px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 text-sm text-gray-500 hover:text-violet-600 hover:border-violet-400 dark:hover:border-violet-500 transition-colors"
                  title="Create new group"
                >
                  <.icon name="hero-plus" class="size-4" />
                </button>
              </div>
            </div>

            <%!-- Tech stack --%>
            <.input
              field={@form[:tech_stack]}
              type="text"
              label="Tech stack"
              placeholder="e.g. Elixir, Phoenix, PostgreSQL"
            />

            <%!-- URL --%>
            <.input
              field={@form[:url]}
              type="url"
              label="URL"
              placeholder="https://github.com/you/project"
            />

            <%!-- Enable tasks toggle (integrated into form flow) --%>
            <div class="flex items-center gap-3">
              <label
                for="toggle-tasks-enabled"
                class="text-sm font-medium text-gray-700 dark:text-gray-300 w-36"
              >
                Enable tasks
              </label>
              <div class="flex items-center gap-3">
                <.switch
                  id="toggle-tasks-enabled"
                  checked={@project && @project.tasks_enabled}
                  phx-click="toggle_tasks_enabled"
                  phx-value-enabled={if @project && @project.tasks_enabled, do: "false", else: "true"}
                />
              </div>
            </div>

            <%!-- Notes --%>
            <.input
              field={@form[:notes]}
              type="textarea"
              label="Notes"
              placeholder="Anything to help you pick up where you left off…"
              rows={5}
            />

            <%!-- Actions --%>
            <div class="flex items-center justify-end gap-3 pt-2 border-t border-gray-100 dark:border-gray-800">
              <.button
                link_type="live_redirect"
                to={return_path(@return_to, @project)}
                variant="ghost"
                color="gray"
              >
                Cancel
              </.button>

              <.button type="submit" phx-disable-with="Saving…">
                {if @live_action == :new, do: "Create project", else: "Save changes"}
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:colors, @colors)
     |> assign(:statuses, @statuses)
     |> assign(:groups, Projects.list_project_groups())
     |> assign(:show_new_group, false)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @spec return_to(String.t() | nil) :: String.t()
  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @spec apply_action(Phoenix.LiveView.Socket.t(), atom(), map()) :: Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, nil)
    |> assign(
      :form,
      AshPhoenix.Form.for_create(Forge.Projects.Project, :create, domain: Forge.Projects)
      |> to_form()
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    project = Projects.get_project!(id)

    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, project)
    |> assign(
      :form,
      AshPhoenix.Form.for_update(project, :update, domain: Forge.Projects) |> to_form()
    )
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    params =
      case Map.get(params, "tasks_enabled") do
        "" ->
          # Prevent intermediate empty values from overwriting the persisted setting when toggling
          if socket.assigns[:project] do
            Map.put(params, "tasks_enabled", to_string(socket.assigns.project.tasks_enabled))
          else
            params
          end

        _ ->
          params
      end

    form =
      AshPhoenix.Form.validate(socket.assigns.form.source, params) |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    save_project(socket, socket.assigns.live_action, params)
  end

  def handle_event("toggle_new_group", _params, socket) do
    {:noreply, assign(socket, :show_new_group, !socket.assigns.show_new_group)}
  end

  def handle_event("create_group", %{"new_group_name" => name}, socket) do
    do_create_group(socket, name)
  end

  def handle_event("toggle_tasks_enabled", %{"enabled" => enabled}, socket) do
    project = socket.assigns.project
    new_val = enabled in ["true", true, true]

    case Projects.update_project(project, %{"tasks_enabled" => new_val}) do
      {:ok, updated} ->
        form = AshPhoenix.Form.for_update(updated, :update, domain: Forge.Projects) |> to_form()
        {:noreply, assign(socket, project: updated, form: form)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not toggle tasks setting")}
    end
  end

  defp do_create_group(socket, name) do
    case Projects.create_project_group(%{"name" => name}) do
      {:ok, group} ->
        groups = Projects.list_project_groups()
        current_source = socket.assigns.form.source

        updated_form =
          AshPhoenix.Form.validate(current_source, %{"project_group_id" => group.id})
          |> to_form()

        {:noreply,
         socket
         |> assign(:groups, groups)
         |> assign(:show_new_group, false)
         |> assign(:form, updated_form)}

      {:error, %Ash.Error.Invalid{} = error} ->
        msg = error |> Ash.Error.to_error_class() |> inspect()
        {:noreply, put_flash(socket, :error, "Could not create group: #{msg}")}
    end
  end

  @spec save_project(Phoenix.LiveView.Socket.t(), atom(), map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp save_project(socket, :new, params) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created!")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  defp save_project(socket, :edit, params) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated!")
         |> push_navigate(to: return_path(socket.assigns.return_to, project))}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @spec return_path(String.t(), Forge.Projects.Project.t()) :: String.t()
  defp return_path("index", _), do: ~p"/projects"
  defp return_path("show", project), do: ~p"/projects/#{project}"
  defp return_path(_, _), do: ~p"/projects"

  @spec color_dot(String.t()) :: String.t()
  defp color_dot("blue"), do: "bg-blue-500 border-blue-500 peer-checked:ring-blue-500"
  defp color_dot("violet"), do: "bg-violet-500 border-violet-500 peer-checked:ring-violet-500"
  defp color_dot("emerald"), do: "bg-emerald-500 border-emerald-500 peer-checked:ring-emerald-500"
  defp color_dot("amber"), do: "bg-amber-500 border-amber-500 peer-checked:ring-amber-500"
  defp color_dot("rose"), do: "bg-rose-500 border-rose-500 peer-checked:ring-rose-500"
  defp color_dot("orange"), do: "bg-orange-500 border-orange-500 peer-checked:ring-orange-500"
  defp color_dot("sky"), do: "bg-sky-500 border-sky-500 peer-checked:ring-sky-500"
  defp color_dot(_), do: "bg-gray-300 border-gray-300"

  @spec peer_ring(String.t()) :: String.t()
  defp peer_ring("blue"), do: "peer-checked:ring-blue-500"
  defp peer_ring("violet"), do: "peer-checked:ring-violet-500"
  defp peer_ring("emerald"), do: "peer-checked:ring-emerald-500"
  defp peer_ring("amber"), do: "peer-checked:ring-amber-500"
  defp peer_ring("rose"), do: "peer-checked:ring-rose-500"
  defp peer_ring("orange"), do: "peer-checked:ring-orange-500"
  defp peer_ring("sky"), do: "peer-checked:ring-sky-500"
  defp peer_ring(_), do: "peer-checked:ring-gray-400"
end
