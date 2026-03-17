defmodule ForgeWeb.TaskComponents do
  use Phoenix.Component
  use ForgeWeb, :verified_routes
  use PetalComponents

  import ForgeWeb.CoreComponents
  import ForgeWeb.SharedHelpers
  import ForgeWeb.UIComponents
  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # Task section — summary card
  # ---------------------------------------------------------------------------

  attr :project,      :map,  required: true
  attr :tasks,        :list, required: true
  attr :project_tags, :list, required: true

  def task_section(assigns) do
    done  = Enum.count(assigns.tasks, &(&1.status == :done))
    total = length(assigns.tasks)
    pct   = if total > 0, do: round(done / total * 100), else: 0
    assigns = assigns |> assign(:done, done) |> assign(:total, total) |> assign(:pct, pct)

    ~H"""
    <div class="border-t border-zinc-100 pt-3">
      <div class="flex justify-between items-center mb-2">
        <.section_label>Tasks</.section_label>
        <span class="text-xs text-zinc-400"><%= @done %> / <%= @total %> klara</span>
      </div>
      <div class="flex items-center gap-2 mb-3">
        <div class="flex-1">
          <.progress value={@pct} size="xs" color="success" />
        </div>
        <span class="text-xs text-zinc-400"><%= @pct %>%</span>
      </div>
      <div id={"task-list-#{@project.id}"} phx-hook="SortableTasks" class="divide-y divide-zinc-50">
        <.task_row :for={task <- @tasks} task={task} />
      </div>
      <form phx-submit="add_task" class="flex gap-2 mt-2 pt-2 border-t border-zinc-50">
        <input name="title"
          placeholder="+ Ny task — Enter för att spara"
          class="flex-1 border-0 border-b border-zinc-200 bg-transparent px-0 py-1
                 text-xs outline-none focus:border-zinc-400 text-zinc-700 placeholder-zinc-400" />
        <select name="priority"
          class="border border-zinc-200 rounded px-1.5 py-1 text-xs bg-zinc-50 text-zinc-500 outline-none">
          <option value="high">Hög</option>
          <option value="medium" selected>Medium</option>
          <option value="low">Låg</option>
        </select>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Expanderbar task-rad
  # ---------------------------------------------------------------------------

  attr :task, :map, required: true

  def task_row(assigns) do
    tags = case assigns.task.tags do
      %Ash.NotLoaded{} -> []
      tags when is_list(tags) -> tags
      _ -> []
    end
    initial_tags = tags |> Enum.map(& &1.name) |> Enum.join(",")
    hidden_id    = "tags-hidden-#{assigns.task.id}"
    assigns = assigns |> assign(:tags, tags) |> assign(:initial_tags, initial_tags) |> assign(:hidden_id, hidden_id)

    ~H"""
    <div id={"task-#{@task.id}"} data-task-id={@task.id}
      class={["group", @task.status == :done && "opacity-60"]}>

      <div class="flex items-center gap-2 py-2 cursor-pointer"
        phx-click={JS.toggle(to: "#task-expand-#{@task.id}")}>
        <div data-drag-handle class="flex flex-col gap-0.5 px-0.5 flex-shrink-0 cursor-grab">
          <span class="block w-3 h-px bg-zinc-300 rounded"></span>
          <span class="block w-3 h-px bg-zinc-300 rounded"></span>
          <span class="block w-3 h-px bg-zinc-300 rounded"></span>
        </div>

        <button phx-click="toggle_task" phx-value-id={@task.id}
          class={[
            "w-4 h-4 rounded border flex-shrink-0 flex items-center justify-center",
            @task.status == :done && "bg-emerald-500 border-emerald-500" || "border-zinc-300 hover:border-zinc-400"
          ]}>
          <svg :if={@task.status == :done} class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 10 8">
            <path d="M1 4l3 3 5-5" stroke="currentColor" stroke-width="1.5"
              stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>

        <span class={["flex-1 text-xs min-w-0 truncate",
          @task.status == :done && "line-through text-zinc-400" || "text-zinc-700"]}>
          <%= @task.title %>
          <span :if={@task.journal_entry_id} class="ml-1 text-zinc-300" title="Kopplad till loggpost">📝</span>
        </span>

        <.task_status_badge status={@task.status} />
        <span class="opacity-0 group-hover:opacity-100 transition-opacity">
          <.priority_badge priority={@task.priority} />
        </span>
        <span :if={@task.due_date}
          class={"text-xs flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity #{due_cls(@task.due_date)}"}>
          <%= due_label(@task.due_date) %>
        </span>
        <.button phx-click="delete_task" phx-value-id={@task.id}
            variant="ghost" color="danger" size="xs"
            class="opacity-0 group-hover:opacity-100 transition-opacity">
            ×
          </.button>
      </div>

      <div id={"task-expand-#{@task.id}"} class="hidden pb-2 pl-10">
        <form phx-submit="update_task_tags">
          <input type="hidden" name="task_id" value={@task.id} />
          <input type="hidden" id={@hidden_id} name="tags" value={@initial_tags} />
          <div id={"chip-input-#{@task.id}"}
            phx-hook="ChipInput"
            data-hidden-input={@hidden_id}
            data-initial-tags={@initial_tags}
            data-placeholder="Lägg till tagg..."
            class="mb-1.5">
          </div>
          <.button type="submit" variant="outline" color="gray" size="xs">
            Spara taggar
          </.button>
        </form>
        <div :if={@task.journal_entry_id} class="mt-1.5">
          <span class="text-xs text-zinc-400">Skapad i loggpost</span>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Task entry block — inuti journal_entry_card
  # ---------------------------------------------------------------------------

  attr :entry,       :map,  required: true
  attr :entry_tasks, :list, required: true

  def task_entry_block(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <:title><span class="font-mono text-xs text-zinc-400">:::task</span></:title>
        <:right>
          <span class="text-xs text-zinc-400"><%= length(@entry_tasks) %> tasks</span>
        </:right>
      </.card_header>
      <div class="divide-y divide-zinc-50">
        <div :for={task <- @entry_tasks}
          class={["flex items-center gap-2 px-3 py-2", task.status == :done && "bg-zinc-50/50"]}>
          <div class={[
            "w-3.5 h-3.5 rounded border flex-shrink-0 flex items-center justify-center",
            task.status == :done && "bg-emerald-500 border-emerald-500" || "border-zinc-300"
          ]}>
            <svg :if={task.status == :done} class="w-2 h-2 text-white" fill="none" viewBox="0 0 10 8">
              <path d="M1 4l3 3 5-5" stroke="currentColor" stroke-width="1.5"
                stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <span class={["flex-1 text-xs",
            task.status == :done && "line-through text-zinc-400" || "text-zinc-600"]}>
            <%= task.title %>
          </span>
          <.task_status_badge status={task.status} />
          <.button phx-click="delete_task" phx-value-id={task.id}
            variant="ghost" color="danger" size="xs">
            ×
          </.button>
        </div>
      </div>
    </.card>
    """
  end
end
