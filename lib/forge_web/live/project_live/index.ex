defmodule ForgeWeb.ProjectLive.Index do
  use ForgeWeb, :live_view
  use PetalComponents

  import ForgeWeb.CoreComponents
  import ForgeWeb.UIComponents
  alias Forge.{Project, Category}
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:categories, Category.list_all!())
     |> assign(:projects, load_projects(nil))
     |> assign(:active_cat, nil)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter", %{"cat" => id}, socket) do
    cat_id = if id == "", do: nil, else: id
    {:noreply,
     socket
     |> assign(:active_cat, cat_id)
     |> assign(:projects, load_projects(cat_id))}
  end

  def handle_event("validate_entry", _params, socket), do: {:noreply, socket}

  def handle_event("create", %{"project" => p}, socket) do
    case Project.create(p) do
      {:ok, project} ->
        {:noreply, push_navigate(socket, to: ~p"/projects/#{project.id}")}
      {:error, err} ->
        {:noreply, put_flash(socket, :error, inspect(err))}
    end
  end

  defp load_projects(nil), do: Project.list!(load: [:category])
  defp load_projects(id),  do: Project.list_by_category!(id, load: [:category])

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-xl font-medium">Mina projekt</h1>
        <.button navigate={~p"/projects/new"} variant="outline" color="gray" size="sm">
          + Nytt projekt
        </.button>
      </div>

      <div class="flex gap-2 mb-6 flex-wrap">
        <.button phx-click="filter" phx-value-cat=""
          variant={if @active_cat == nil, do: "solid", else: "outline"}
          color="gray" size="sm">
          Alla
        </.button>
        <.button :for={cat <- @categories}
          phx-click="filter" phx-value-cat={cat.id}
          variant={if @active_cat == cat.id, do: "solid", else: "outline"}
          color="gray" size="sm">
          <%= cat.icon %> <%= cat.name %>
        </.button>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <.link :for={p <- @projects} navigate={~p"/projects/#{p.id}"}
          class="border border-zinc-200 rounded-xl overflow-hidden
                 hover:border-zinc-300 transition-colors block">
          <div class="h-24 bg-zinc-50 flex items-center justify-center text-3xl">
            <%= p.category && p.category.icon || "📁" %>
          </div>
          <div class="p-3">
            <.status_badge status={p.status} />
            <div class="font-medium text-sm mt-2"><%= p.name %></div>
            <div class="text-xs text-zinc-400 mt-1 line-clamp-2"><%= p.description %></div>
          </div>
        </.link>
      </div>

      <.modal :if={@live_action == :new} id="new-project-modal" show on_cancel={JS.patch(~p"/")}>
        <:title>Nytt projekt</:title>
        <form phx-submit="create" phx-change="validate_entry" id="pform" class="space-y-4">
          <div>
            <label class="block text-sm text-zinc-600 mb-1">Namn</label>
            <input name="project[name]" required
              class="w-full border border-zinc-200 rounded-lg px-3 py-2 text-sm
                     outline-none focus:border-zinc-400" />
          </div>
          <div>
            <label class="block text-sm text-zinc-600 mb-1">Beskrivning</label>
            <textarea name="project[description]" rows="3"
              class="w-full border border-zinc-200 rounded-lg px-3 py-2 text-sm
                     outline-none focus:border-zinc-400 resize-none"></textarea>
          </div>
          <div>
            <label class="block text-sm text-zinc-600 mb-1">Kategori</label>
            <select name="project[category_id]"
              class="w-full border border-zinc-200 rounded-lg px-3 py-2 text-sm
                     outline-none focus:border-zinc-400">
              <option value="">Välj kategori</option>
              <option :for={cat <- @categories} value={cat.id}><%= cat.name %></option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-zinc-600 mb-1">Status</label>
            <select name="project[status]"
              class="w-full border border-zinc-200 rounded-lg px-3 py-2 text-sm
                     outline-none focus:border-zinc-400">
              <option value="idea">Idé</option>
              <option value="active">Aktiv</option>
              <option value="on_hold">Pausad</option>
              <option value="done">Klar</option>
            </select>
          </div>
          <div class="flex justify-end gap-2 pt-2">
            <.button patch={~p"/"} variant="ghost" color="gray">Avbryt</.button>
            <.button type="submit" color="gray">Skapa projekt</.button>
          </div>
        </form>
      </.modal>
    </div>
    """
  end
end
