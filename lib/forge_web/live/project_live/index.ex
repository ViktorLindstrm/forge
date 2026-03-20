defmodule ForgeWeb.ProjectLive.Index do
  use ForgeWeb, :live_view

  alias Forge.Projects

  @status_filters [
    {"All", "all"},
    {"Active", "active"},
    {"Ideas", "idea"},
    {"Paused", "paused"},
    {"Done", "done"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%!-- Page header --%>
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Projects</h1>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
            {@total_count} project{if @total_count != 1, do: "s", else: ""}
          </p>
        </div>
        <.link
          navigate={~p"/projects/new"}
          class="inline-flex items-center justify-center gap-2 rounded-xl bg-violet-600 px-4 py-2 text-sm font-semibold text-white hover:bg-violet-500 transition-colors"
          id="projects-new"
        >
          <.icon name="hero-plus" class="size-4" /> New Project
        </.link>
      </div>

      <%!-- Stats row --%>
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
        <.stat_card
          label="Active"
          count={Map.get(@counts, "active", 0)}
          color="emerald"
          icon="hero-bolt"
        />
        <.stat_card
          label="Ideas"
          count={Map.get(@counts, "idea", 0)}
          color="violet"
          icon="hero-light-bulb"
        />
        <.stat_card
          label="Paused"
          count={Map.get(@counts, "paused", 0)}
          color="amber"
          icon="hero-pause-circle"
        />
        <.stat_card
          label="Done"
          count={Map.get(@counts, "done", 0)}
          color="blue"
          icon="hero-check-circle"
        />
      </div>

      <%!-- Status filter tabs --%>
      <div class="flex gap-1 mb-6 bg-gray-100 dark:bg-gray-800 rounded-xl p-1 w-fit">
        <%= for {label, value} <- @status_filters do %>
          <button
            phx-click="filter"
            phx-value-status={value}
            class={[
              "px-3 py-1.5 rounded-lg text-sm font-medium transition-all",
              @active_filter == value &&
                "bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm",
              @active_filter != value &&
                "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
            ]}
          >
            {label}
          </button>
        <% end %>
      </div>

      <%!-- Project cards grid --%>
      <%= if @total_count == 0 do %>
        <.empty_state />
      <% else %>
        <div
          id="projects"
          phx-update="stream"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          <div
            :for={{id, project} <- @streams.projects}
            id={id}
            class="hidden only:flex flex-col items-center justify-center py-16 col-span-full text-gray-400 dark:text-gray-600"
          >
            <.icon name="hero-funnel" class="size-8 mb-2" />
            <p class="text-sm">No projects match this filter</p>
          </div>
          <.project_card :for={{id, project} <- @streams.projects} id={id} project={project} />
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :project, :any, required: true

  defp project_card(assigns) do
    ~H"""
    <div
      id={@id}
      class="group relative bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-5 hover:shadow-md hover:border-gray-300 dark:hover:border-gray-700 transition-all duration-200 flex flex-col gap-3"
    >
      <%!-- Color accent bar --%>
      <div class={["absolute top-0 left-0 right-0 h-1 rounded-t-2xl", color_bg(@project.color)]} />

      <div class="flex items-start justify-between gap-2 pt-1">
        <div class="flex-1 min-w-0">
          <.link navigate={~p"/projects/#{@project}"} class="block">
            <h3 class="font-semibold text-gray-900 dark:text-white text-base leading-tight truncate hover:text-violet-600 dark:hover:text-violet-400 transition-colors">
              {@project.name}
            </h3>
          </.link>
          <p
            :if={@project.tech_stack}
            class="text-xs text-gray-400 dark:text-gray-500 mt-0.5 truncate"
          >
            {@project.tech_stack}
          </p>
        </div>
        <.status_badge status={@project.status} />
      </div>

      <p
        :if={@project.description}
        class="text-sm text-gray-600 dark:text-gray-400 line-clamp-2 leading-relaxed"
      >
        {@project.description}
      </p>

      <div class="flex items-center justify-between mt-auto pt-1">
        <a
          :if={@project.url}
          href={@project.url}
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-1 text-xs text-gray-400 hover:text-violet-500 transition-colors truncate max-w-[160px]"
        >
          <.icon name="hero-link" class="size-3 shrink-0" />
          <span class="truncate">{url_display(@project.url)}</span>
        </a>
        <span :if={!@project.url} />

        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <.link
            navigate={~p"/projects/#{@project}/edit"}
            class="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            title="Edit"
          >
            <.icon name="hero-pencil" class="size-3.5" />
          </.link>
          <button
            phx-click="delete"
            phx-value-id={@project.id}
            data-confirm="Delete this project?"
            class="p-1.5 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors"
            title="Delete"
          >
            <.icon name="hero-trash" class="size-3.5" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :color, :string, required: true
  attr :icon, :string, required: true

  defp stat_card(assigns) do
    ~H"""
    <div class={[
      "rounded-xl p-3 flex items-center gap-3",
      stat_bg(@color)
    ]}>
      <div class={["p-2 rounded-lg", stat_icon_bg(@color)]}>
        <.icon name={@icon} class={["size-4", stat_icon_color(@color)]} />
      </div>
      <div>
        <p class={["text-xl font-bold leading-none", stat_text(@color)]}>{@count}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{@label}</p>
      </div>
    </div>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-24 text-center">
      <div class="size-16 rounded-2xl bg-gradient-to-br from-violet-100 to-blue-100 dark:from-violet-900/30 dark:to-blue-900/30 flex items-center justify-center mb-4">
        <.icon name="hero-rocket-launch" class="size-8 text-violet-500" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-1">No projects yet</h3>
      <p class="text-sm text-gray-500 dark:text-gray-400 mb-6 max-w-xs">
        Start tracking your projects. Add your first one to get going.
      </p>
      <.link
        navigate={~p"/projects/new"}
        class="inline-flex items-center justify-center gap-2 rounded-xl bg-violet-600 px-4 py-2 text-sm font-semibold text-white hover:bg-violet-500 transition-colors"
        id="projects-empty-new"
      >
        <.icon name="hero-plus" class="size-4" /> New Project
      </.link>
    </div>
    """
  end

  attr :status, :string, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium shrink-0",
      status_classes(@status)
    ]}>
      <span class={["size-1.5 rounded-full", status_dot(@status)]} />
      {String.capitalize(@status)}
    </span>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    counts = Projects.count_by_status()
    total = counts |> Map.values() |> Enum.sum()

    {:ok,
     socket
     |> assign(:page_title, "Projects · Forge")
     |> assign(:status_filters, @status_filters)
     |> assign(:active_filter, "all")
     |> assign(:counts, counts)
     |> assign(:total_count, total)
     |> stream(:projects, Projects.list_projects())}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    projects =
      if status == "all",
        do: Projects.list_projects(),
        else: Projects.list_projects_by_status(status)

    {:noreply,
     socket
     |> assign(:active_filter, status)
     |> stream(:projects, projects, reset: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(project)

    counts = Projects.count_by_status()
    total = counts |> Map.values() |> Enum.sum()

    {:noreply,
     socket
     |> assign(:counts, counts)
     |> assign(:total_count, total)
     |> stream_delete(:projects, project)}
  end

  defp status_classes("active"),
    do: "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"

  defp status_classes("idea"),
    do: "bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400"

  defp status_classes("paused"),
    do: "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"

  defp status_classes("done"),
    do: "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"

  defp status_classes(_), do: "bg-gray-50 text-gray-700 dark:bg-gray-800 dark:text-gray-400"

  defp status_dot("active"), do: "bg-emerald-500"
  defp status_dot("idea"), do: "bg-violet-500"
  defp status_dot("paused"), do: "bg-amber-500"
  defp status_dot("done"), do: "bg-blue-500"
  defp status_dot(_), do: "bg-gray-400"

  defp color_bg("blue"), do: "bg-gradient-to-r from-blue-400 to-blue-600"
  defp color_bg("violet"), do: "bg-gradient-to-r from-violet-400 to-violet-600"
  defp color_bg("emerald"), do: "bg-gradient-to-r from-emerald-400 to-emerald-600"
  defp color_bg("amber"), do: "bg-gradient-to-r from-amber-400 to-amber-600"
  defp color_bg("rose"), do: "bg-gradient-to-r from-rose-400 to-rose-600"
  defp color_bg("orange"), do: "bg-gradient-to-r from-orange-400 to-orange-600"
  defp color_bg("sky"), do: "bg-gradient-to-r from-sky-400 to-sky-600"
  defp color_bg(_), do: "bg-gradient-to-r from-gray-300 to-gray-400"

  defp stat_bg("emerald"), do: "bg-emerald-50 dark:bg-emerald-900/20"
  defp stat_bg("violet"), do: "bg-violet-50 dark:bg-violet-900/20"
  defp stat_bg("amber"), do: "bg-amber-50 dark:bg-amber-900/20"
  defp stat_bg("blue"), do: "bg-blue-50 dark:bg-blue-900/20"
  defp stat_bg(_), do: "bg-gray-50 dark:bg-gray-800"

  defp stat_icon_bg("emerald"), do: "bg-emerald-100 dark:bg-emerald-900/50"
  defp stat_icon_bg("violet"), do: "bg-violet-100 dark:bg-violet-900/50"
  defp stat_icon_bg("amber"), do: "bg-amber-100 dark:bg-amber-900/50"
  defp stat_icon_bg("blue"), do: "bg-blue-100 dark:bg-blue-900/50"
  defp stat_icon_bg(_), do: "bg-gray-100 dark:bg-gray-700"

  defp stat_icon_color("emerald"), do: "text-emerald-600 dark:text-emerald-400"
  defp stat_icon_color("violet"), do: "text-violet-600 dark:text-violet-400"
  defp stat_icon_color("amber"), do: "text-amber-600 dark:text-amber-400"
  defp stat_icon_color("blue"), do: "text-blue-600 dark:text-blue-400"
  defp stat_icon_color(_), do: "text-gray-500"

  defp stat_text("emerald"), do: "text-emerald-700 dark:text-emerald-300"
  defp stat_text("violet"), do: "text-violet-700 dark:text-violet-300"
  defp stat_text("amber"), do: "text-amber-700 dark:text-amber-300"
  defp stat_text("blue"), do: "text-blue-700 dark:text-blue-300"
  defp stat_text(_), do: "text-gray-700 dark:text-gray-300"

  defp url_display(url) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/\/$/, "")
  end
end
