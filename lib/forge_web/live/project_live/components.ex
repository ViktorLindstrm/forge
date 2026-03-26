defmodule ForgeWeb.ProjectLive.Components do
  use ForgeWeb, :html

  alias ForgeWeb.ProjectLive.Components.Badges
  alias ForgeWeb.ProjectLive.Components.BomHelpers
  alias ForgeWeb.ProjectLive.Components.Formatting

  alias ForgeWeb.ProjectLive.Bom
  alias ForgeWeb.ProjectLive.Notes

  alias ForgeWeb.ProjectLive.Components.Pills

  defdelegate pill(assigns), to: Pills
  defdelegate color_bg(color), to: Badges
  defdelegate url_display(url), to: Formatting

  @spec bom_form() :: Phoenix.HTML.Form.t()
  def bom_form, do: Bom.bom_form()

  @spec note_form() :: Phoenix.HTML.Form.t()
  def note_form, do: Notes.note_form()

  @spec status_badge(map()) :: Phoenix.LiveView.Rendered.t()
  defdelegate status_badge(assigns), to: Badges

  @spec summary_grid(map()) :: Phoenix.LiveView.Rendered.t()
  attr :task_counts, :map, required: true
  attr :project, :any, required: true
  attr :bom_budget, :any, required: true
  attr :note_count, :integer, required: true

  def summary_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-3 gap-4" id="project-summary">
      <.summary_card
        label="Tasks"
        value={task_progress_label(@task_counts)}
        icon="hero-check-badge"
        color="violet"
      />
      <.summary_card
        label="BOM"
        value={bom_progress_label(@bom_budget)}
        icon="hero-shopping-cart"
        color="amber"
      />
      <.summary_card
        label="Notes"
        value={"#{@note_count} note" <> if @note_count == 1, do: "", else: "s"}
        icon="hero-document-text"
        color="sky"
      />

      <span class="hidden" id="summary-notes">{@note_count} note</span>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, required: true
  attr :color, :string, required: true

  defp summary_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
      <div class="flex items-center gap-2 mb-2">
        <.icon name={@icon} class={["size-5", summary_icon_color(@color)]} />
        <p class="text-sm font-semibold text-gray-700 dark:text-gray-200">{@label}</p>
      </div>
      <p class="text-xl font-bold text-gray-900 dark:text-white">{@value}</p>
    </div>
    """
  end

  @spec tasks_component(map()) :: Phoenix.LiveView.Rendered.t()
  attr :task_counts, :map, required: true
  attr :task_form, :any, required: true
  attr :task_form_open?, :boolean, required: true
  attr :expanded_task_id, :any, required: true
  attr :editing_task_id, :any, required: true
  attr :task_edit_form, :any, required: true
  attr :streams, :map, required: true
  attr :tasks_empty?, :boolean, required: true
  attr :sections_open, :map, required: true
  attr :subtask_form_task_id, :any, default: nil
  attr :collapsed_subtasks, :any, default: MapSet.new()

  def tasks_component(assigns) do
    ~H"""
    <div
      class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6"
      id="project-tasks"
    >
      <button
        type="button"
        phx-click="toggle_section"
        phx-value-section="tasks"
        class="w-full flex items-center justify-between gap-4 text-left"
        id="project-tasks-toggle"
      >
        <div>
          <h2 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <.icon name="hero-check-badge" class="size-4 text-gray-400" /> Tasks
          </h2>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {task_progress_label(@task_counts)}
          </p>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs text-gray-400 dark:text-gray-500">
            {if @sections_open.tasks, do: "Hide", else: "Show"}
          </span>
          <.icon
            name={if @sections_open.tasks, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="size-4 text-gray-400"
          />
        </div>
      </button>

      <div class={["pt-4", if(@sections_open.tasks, do: "", else: "hidden")]} id="project-tasks-body">
        <div
          :if={@tasks_empty?}
          class="text-sm text-gray-400 dark:text-gray-600 italic py-6"
          id="task-list-empty"
        >
          No tasks yet. Add your first next step.
        </div>

        <div class="space-y-2" id="task-list" phx-update="stream" phx-hook="TaskSortable">
          <div
            :for={{id, task} <- @streams.tasks}
            id={id}
            data-task-id={task.id}
            data-subtask-of={task.parent_task_id}
            draggable={if is_nil(task.parent_task_id), do: "true", else: "false"}
            class={[
              "group rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40",
              is_nil(task.parent_task_id) && "px-3 py-2",
              !is_nil(task.parent_task_id) &&
                "ml-8 border-l border-gray-200 dark:border-gray-800 pl-4 pr-3 py-2"
            ]}
          >
            <div class="flex items-center gap-3">
              <button
                phx-click="task_toggle"
                phx-value-id={task.id}
                class={[
                  "size-5 rounded-md border flex items-center justify-center transition-colors shrink-0",
                  task.status == :done && "bg-emerald-600 border-emerald-600 text-white",
                  task.status != :done &&
                    "bg-white dark:bg-gray-900 border-gray-300 dark:border-gray-700 text-transparent hover:border-gray-400 dark:hover:border-gray-500"
                ]}
                aria-label="Toggle task done"
                id={"task-toggle-#{task.id}"}
              >
                <.icon name="hero-check" class="size-3.5" />
              </button>

              <div class="min-w-0 flex-1">
                <div class="flex items-center justify-between gap-3">
                  <div class="min-w-0 flex items-center gap-1.5">
                    <button
                      :if={is_nil(task.parent_task_id)}
                      type="button"
                      data-handle
                      aria-label="Drag to reorder"
                      class="cursor-grab active:cursor-grabbing text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 shrink-0"
                      id={"task-drag-handle-#{task.id}"}
                    >
                      <.icon name="hero-bars-3" class="size-4" />
                    </button>

                    <button
                      :if={!is_nil(task.parent_task_id)}
                      type="button"
                      data-subtask-handle
                      aria-label="Drag to reorder"
                      class="cursor-grab active:cursor-grabbing text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 shrink-0"
                      id={"subtask-drag-handle-#{task.id}"}
                    >
                      <.icon name="hero-bars-3" class="size-3.5" />
                    </button>

                    <button
                      :if={
                        task.status != :done && to_string(task.description || "") != "" &&
                          is_nil(task.parent_task_id)
                      }
                      type="button"
                      phx-click="task_details_toggle"
                      phx-value-id={task.id}
                      class="shrink-0 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 transition-colors"
                      aria-expanded={@expanded_task_id == task.id}
                      aria-controls={"task-details-#{task.id}"}
                      id={"task-details-toggle-#{task.id}"}
                    >
                      <.icon
                        name="hero-chevron-right"
                        class={[
                          "size-3.5 transition-transform",
                          if(@expanded_task_id == task.id, do: "rotate-90")
                        ]}
                      />
                    </button>

                    <div class="min-w-0 flex items-center gap-2">
                      <p class={[
                        "text-sm font-medium truncate",
                        task.status == :done && "text-gray-400 line-through",
                        task.status != :done && "text-gray-900 dark:text-white"
                      ]}>
                        {task.title}
                      </p>
                      <.pill
                        :if={task.status != :todo && task.status != :done}
                        kind="status"
                        value={task.status}
                      />
                      <.pill kind="priority" value={task.priority} />
                      <button
                        :if={is_nil(task.parent_task_id) && task.subtasks != []}
                        type="button"
                        phx-click={
                          JS.toggle_class("hidden",
                            to: "[data-subtask-of='#{task.id}']"
                          )
                          |> JS.toggle_class("rotate-90",
                            to: "#subtasks-chevron-#{task.id}"
                          )
                        }
                        class="inline-flex items-center gap-1 rounded-md px-1.5 py-0.5 text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                        aria-label="Toggle subtasks"
                        id={"subtasks-toggle-#{task.id}"}
                      >
                        <.icon
                          name="hero-chevron-down"
                          class="size-3 transition-transform"
                          id={"subtasks-chevron-#{task.id}"}
                        />
                        {length(task.subtasks)}
                      </button>
                    </div>
                  </div>

                  <div class="flex items-center gap-1.5 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      :if={task.status != :done and is_nil(task.parent_task_id)}
                      type="button"
                      phx-click="task_pin_cycle"
                      phx-value-id={task.id}
                      class={[
                        "inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium transition-colors",
                        task.pin_status == :current &&
                          "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
                        task.pin_status == :upcoming &&
                          "bg-sky-100 text-sky-800 dark:bg-sky-900/30 dark:text-sky-300",
                        task.pin_status not in [:current, :upcoming] &&
                          "text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-500 dark:hover:text-gray-300 dark:hover:bg-gray-800"
                      ]}
                      aria-label="Cycle pin status"
                      id={"task-pin-cycle-#{task.id}"}
                    >
                      <.icon name="hero-bookmark" class="size-3.5" />
                      {case task.pin_status do
                        :current -> "Current"
                        :upcoming -> "Upcoming"
                        _ -> nil
                      end}
                    </button>

                    <button
                      :if={task.status != :done and is_nil(task.parent_task_id)}
                      type="button"
                      phx-click="subtask_form_open"
                      phx-value-id={task.id}
                      class="p-2 rounded-lg text-gray-400 hover:text-violet-600 hover:bg-violet-50 dark:hover:bg-violet-950 transition-colors"
                      aria-label="Add subtask"
                      id={"subtask-form-open-#{task.id}"}
                    >
                      <.icon name="hero-plus-circle" class="size-4" />
                    </button>

                    <button
                      :if={task.status != :done and is_nil(task.parent_task_id)}
                      type="button"
                      phx-click="task_edit_open"
                      phx-value-id={task.id}
                      class="p-2 rounded-lg text-gray-400 hover:text-violet-600 hover:bg-violet-50 dark:hover:bg-violet-950 transition-colors"
                      aria-label="Edit task"
                      id={"task-edit-#{task.id}"}
                    >
                      <.icon name="hero-pencil-square" class="size-4" />
                    </button>

                    <button
                      phx-click="task_delete"
                      phx-value-id={task.id}
                      data-confirm="Delete this task?"
                      class="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors"
                      aria-label="Delete task"
                      id={"task-delete-#{task.id}"}
                    >
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>

                <div
                  :if={@editing_task_id == task.id && is_nil(task.parent_task_id)}
                  class="mt-3 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 overflow-hidden"
                  id={"task-edit-wrapper-#{task.id}"}
                >
                  <.form
                    for={@task_edit_form}
                    id={"task-edit-form-#{task.id}"}
                    phx-submit="task_edit_save"
                    phx-change="task_edit_validate"
                  >
                    <input type="hidden" name="task_id" value={task.id} />
                    <div class="divide-y divide-gray-100 dark:divide-gray-800">
                      <.field
                        field={@task_edit_form[:title]}
                        type="text"
                        label="Task"
                        wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                        label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                        class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                      />
                      <div class="grid grid-cols-2 divide-x divide-gray-100 dark:divide-gray-800">
                        <.field
                          field={@task_edit_form[:priority]}
                          type="select"
                          label="Priority"
                          options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]}
                          wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                          label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                          class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0"
                        />
                        <.field
                          field={@task_edit_form[:status]}
                          type="select"
                          label="Status"
                          options={[
                            {"To do", "todo"},
                            {"In progress", "in_progress"},
                            {"Blocked", "blocked"}
                          ]}
                          wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                          label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                          class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0"
                        />
                      </div>
                      <div class="flex items-start gap-3 px-3 py-2">
                        <label class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400">
                          Description
                        </label>
                        <textarea
                          name={@task_edit_form[:description].name}
                          id={@task_edit_form[:description].id}
                          rows="1"
                          placeholder="Details, context, links…"
                          class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600 resize-none text-gray-900 dark:text-white"
                        >{Phoenix.HTML.Form.normalize_value("textarea", @task_edit_form[:description].value)}</textarea>
                        <div class="shrink-0 self-end flex items-center gap-3 border-l border-gray-200 dark:border-gray-700 pl-3">
                          <button
                            type="button"
                            phx-click="task_edit_cancel"
                            class="text-sm font-medium text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
                            id={"task-edit-cancel-#{task.id}"}
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            phx-disable-with="Saving…"
                            class="text-sm font-semibold text-violet-600 hover:text-violet-500 transition-colors disabled:opacity-50"
                            id={"task-edit-save-#{task.id}"}
                          >
                            Save
                          </button>
                        </div>
                      </div>
                    </div>
                  </.form>
                </div>

                <div
                  id={"task-details-#{task.id}"}
                  class={[
                    "mt-1 border-t border-gray-100 dark:border-gray-800 bg-white/50 dark:bg-gray-950/30 px-3 py-3",
                    if(to_string(@expanded_task_id) == to_string(task.id), do: "", else: "hidden")
                  ]}
                >
                  <div class="text-sm text-gray-700 dark:text-gray-300 whitespace-pre-line leading-relaxed">
                    {task.description}
                  </div>
                </div>
              </div>
            </div>

            <div
              :if={
                is_nil(task.parent_task_id) and
                  to_string(@subtask_form_task_id) == to_string(task.id)
              }
              class="ml-8 mt-2 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 overflow-hidden"
              id={"subtask-form-wrapper-#{task.id}"}
            >
              <.form
                for={@task_form}
                id={"subtask-quick-form-#{task.id}"}
                phx-submit="task_create"
              >
                <input type="hidden" name="parent_task_id" value={task.id} />
                <input type="hidden" name="task[title]" value="" />
                <div class="flex items-center gap-3 px-3 py-2">
                  <label class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400">
                    Subtask
                  </label>
                  <input
                    type="text"
                    name={@task_form[:title].name}
                    id={"subtask-title-#{task.id}"}
                    placeholder="Add subtask…"
                    phx-debounce="200"
                    class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600 text-gray-900 dark:text-white"
                  />
                  <div class="shrink-0 flex items-center gap-3 border-l border-gray-200 dark:border-gray-700 pl-3">
                    <button
                      type="button"
                      phx-click="subtask_form_close"
                      phx-value-id={task.id}
                      class="text-sm font-medium text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
                      id={"subtask-cancel-#{task.id}"}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="text-xs font-semibold text-violet-600 hover:text-violet-500 transition-colors"
                      id={"subtask-add-#{task.id}"}
                    >
                      Add
                    </button>
                  </div>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <div class="flex justify-end mt-3">
          <button
            type="button"
            phx-click="toggle_task_form"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-violet-600 dark:text-violet-400 hover:text-violet-500 transition-colors"
            id="task-add-trigger"
          >
            <.icon name={if @task_form_open?, do: "hero-x-mark", else: "hero-plus"} class="size-4" />
            {if @task_form_open?, do: "Cancel", else: "Add task"}
          </button>
        </div>

        <div
          :if={@task_form_open?}
          id="task-form-wrapper"
          class="mt-3 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 overflow-hidden"
        >
          <.form for={@task_form} id="task-quick-form" phx-submit="task_create">
            <div class="divide-y divide-gray-100 dark:divide-gray-800">
              <.field
                field={@task_form[:title]}
                type="text"
                label="Task"
                placeholder="What's the next step?"
                wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
              />
              <div class="grid grid-cols-2 divide-x divide-gray-100 dark:divide-gray-800">
                <.field
                  field={@task_form[:priority]}
                  type="select"
                  label="Priority"
                  options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]}
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0"
                />
                <.field
                  field={@task_form[:status]}
                  type="select"
                  label="Status"
                  options={[{"To do", "todo"}, {"In progress", "in_progress"}, {"Blocked", "blocked"}]}
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0"
                />
              </div>
              <div class="flex items-start gap-3 px-3 py-2">
                <label class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400">
                  Description
                </label>
                <textarea
                  name={@task_form[:description].name}
                  id={@task_form[:description].id}
                  rows="1"
                  placeholder="Details, context, links…"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600 resize-none text-gray-900 dark:text-white"
                >{Phoenix.HTML.Form.normalize_value("textarea", @task_form[:description].value)}</textarea>
                <button
                  type="submit"
                  phx-disable-with="Adding…"
                  class="shrink-0 self-end text-sm font-semibold text-violet-600 hover:text-violet-500 transition-colors disabled:opacity-50 border-l border-gray-200 dark:border-gray-700 pl-3"
                  id="task-quick-add"
                >
                  Add
                </button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp summary_icon_color("violet"), do: "text-violet-500"
  defp summary_icon_color("amber"), do: "text-amber-500"
  defp summary_icon_color("sky"), do: "text-sky-500"
  defp summary_icon_color("emerald"), do: "text-emerald-500"
  defp summary_icon_color(_), do: "text-gray-400"

  defp task_progress_label(counts) do
    done = Map.get(counts, :done, 0)
    total = counts |> Map.values() |> Enum.sum()

    cond do
      total == 0 -> "No tasks"
      done == total -> "All done"
      true -> "#{done}/#{total} done"
    end
  end

  defp bom_progress_label(%{items: items}) do
    total = Enum.count(items)
    received = Enum.count(items, &(&1.status == :received))

    if total == 0, do: "No items", else: "#{received}/#{total} received"
  end

  @spec bom_component(map()) :: Phoenix.LiveView.Rendered.t()
  attr :sections_open, :map, required: true
  attr :bom_budget, :any, required: true
  attr :bom_form, :any, required: true
  attr :bom_form_open?, :boolean, required: true

  def bom_component(assigns) do
    ~H"""
    <div
      class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6"
      id="project-bom"
    >
      <button
        type="button"
        phx-click="toggle_section"
        phx-value-section="bom"
        class="w-full flex items-center justify-between gap-4 text-left"
        id="project-bom-toggle"
      >
        <div>
          <h2 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <.icon name="hero-shopping-cart" class="size-4 text-gray-400" /> BOM
          </h2>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {BomHelpers.budget_label(@bom_budget)}
          </p>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs text-gray-400 dark:text-gray-500">
            {if @sections_open.bom, do: "Hide", else: "Show"}
          </span>
          <.icon
            name={if @sections_open.bom, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="size-4 text-gray-400"
          />
        </div>
      </button>

      <div class={["pt-4", if(@sections_open.bom, do: "", else: "hidden")]} id="project-bom-body">
        <div
          :if={@bom_budget.items == []}
          class="text-sm text-gray-400 dark:text-gray-600 italic py-6"
        >
          No BOM items yet.
        </div>

        <div :if={@bom_budget.items != []} class="space-y-2" id="bom-list">
          <div
            :for={item <- @bom_budget.items}
            class="group rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 px-3 py-2"
            id={"bom-item-#{item.id}"}
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="text-sm font-medium text-gray-900 dark:text-white truncate">{item.name}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {item.quantity} {item.unit || ""}
                  <%= if item.unit_price do %>
                    · {Formatting.money(BomHelpers.item_total(item))} total
                  <% end %>
                </p>
              </div>
              <div class="flex items-center gap-2 shrink-0">
                <button
                  type="button"
                  phx-click="bom_toggle"
                  phx-value-id={item.id}
                  class={[
                    "inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium transition-colors",
                    BomHelpers.bom_status_classes(item.status)
                  ]}
                  id={"bom-toggle-#{item.id}"}
                >
                  <span class={["size-1.5 rounded-full", BomHelpers.bom_status_dot(item.status)]} />
                  {String.capitalize(to_string(item.status))}
                </button>

                <button
                  type="button"
                  phx-click="bom_delete"
                  phx-value-id={item.id}
                  data-confirm="Delete this item?"
                  class="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors opacity-0 group-hover:opacity-100"
                  aria-label="Delete item"
                  id={"bom-delete-#{item.id}"}
                >
                  <.icon name="hero-trash" class="size-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end mt-3">
          <button
            type="button"
            phx-click="toggle_bom_form"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-violet-600 dark:text-violet-400 hover:text-violet-500 transition-colors"
            id="bom-add-trigger"
          >
            <.icon name={if @bom_form_open?, do: "hero-x-mark", else: "hero-plus"} class="size-4" />
            {if @bom_form_open?, do: "Cancel", else: "Add item"}
          </button>
        </div>

        <div
          :if={@bom_form_open?}
          id="bom-form-wrapper"
          class="mt-4 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 overflow-hidden"
        >
          <.form for={@bom_form} id="bom-quick-form" phx-submit="bom_create">
            <div class="divide-y divide-gray-100 dark:divide-gray-800">
              <.field
                field={@bom_form[:name]}
                type="text"
                label="Name"
                placeholder="e.g. Arduino Uno"
                wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                label_class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
              />
              <div class="grid grid-cols-3 divide-x divide-gray-100 dark:divide-gray-800">
                <.field
                  field={@bom_form[:quantity]}
                  type="number"
                  label="Qty"
                  placeholder="1"
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-8 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                />
                <.field
                  field={@bom_form[:unit]}
                  type="text"
                  label="Unit"
                  placeholder="pcs, m, kg"
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-8 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                />
                <.field
                  field={@bom_form[:unit_price]}
                  type="number"
                  step="0.01"
                  label="Price"
                  placeholder="49.99"
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-8 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                />
              </div>
              <div class="grid grid-cols-2 divide-x divide-gray-100 dark:divide-gray-800">
                <.field
                  field={@bom_form[:supplier]}
                  type="text"
                  label="Supplier"
                  placeholder="Mouser, Digikey…"
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-14 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                />
                <.field
                  field={@bom_form[:link]}
                  type="text"
                  label="Link"
                  placeholder="https://…"
                  wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                  label_class="w-14 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
                />
              </div>
              <div class="flex items-start gap-3 px-3 py-2">
                <label class="w-20 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400">
                  Notes
                </label>
                <textarea
                  name={@bom_form[:notes].name}
                  id={@bom_form[:notes].id}
                  rows="1"
                  placeholder="Lead time, substitutes, extra info…"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600 resize-none text-gray-900 dark:text-white"
                >{Phoenix.HTML.Form.normalize_value("textarea", @bom_form[:notes].value)}</textarea>
                <button
                  type="submit"
                  phx-disable-with="Adding…"
                  class="shrink-0 self-end text-sm font-semibold text-violet-600 hover:text-violet-500 transition-colors disabled:opacity-50 border-l border-gray-200 dark:border-gray-700 pl-3"
                  id="bom-quick-add"
                >
                  Add
                </button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @spec notes_component(map()) :: Phoenix.LiveView.Rendered.t()
  attr :sections_open, :map, required: true
  attr :project, :any, required: true
  attr :note_form, :any, required: true
  attr :note_form_open?, :boolean, required: true
  attr :note_page, :integer, required: true
  attr :note_total_pages, :integer, required: true
  attr :streams, :map, required: true
  attr :notes_empty?, :boolean, required: true

  def notes_component(assigns) do
    ~H"""
    <div
      class="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6"
      id="project-notes"
    >
      <button
        type="button"
        phx-click="toggle_section"
        phx-value-section="notes"
        class="w-full flex items-center justify-between gap-4 text-left"
        id="project-notes-toggle"
      >
        <div>
          <h2 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <.icon name="hero-document-text" class="size-4 text-gray-400" /> Notes
          </h2>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {@note_page}/{@note_total_pages}
          </p>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs text-gray-400 dark:text-gray-500">
            {if @sections_open.notes, do: "Hide", else: "Show"}
          </span>
          <.icon
            name={if @sections_open.notes, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="size-4 text-gray-400"
          />
        </div>
      </button>

      <div class={["pt-4", if(@sections_open.notes, do: "", else: "hidden")]} id="project-notes-body">
        <div
          :if={@notes_empty?}
          class="text-sm text-gray-400 dark:text-gray-600 italic py-6"
          id="notes-empty"
        >
          No notes yet.
        </div>

        <div :if={!@notes_empty?} class="space-y-2" id="notes-list" phx-update="stream">
          <div
            :for={{id, entry} <- @streams.journal_entries}
            id={id}
            class="group rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 px-3 py-2"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p
                  :if={entry.title}
                  class="text-sm font-medium text-gray-900 dark:text-white truncate"
                >
                  {entry.title}
                </p>
                <p class="text-sm text-gray-700 dark:text-gray-200 whitespace-pre-line leading-relaxed">
                  {entry.body}
                </p>
              </div>
              <button
                type="button"
                phx-click="note_delete"
                phx-value-id={entry.id}
                data-confirm="Delete this note?"
                class="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors opacity-0 group-hover:opacity-100"
                aria-label="Delete note"
                id={"note-delete-#{entry.id}"}
              >
                <.icon name="hero-trash" class="size-4" />
              </button>
            </div>
          </div>
        </div>

        <div class="flex justify-between items-center mt-3">
          <div class="flex items-center gap-2">
            <button
              type="button"
              phx-click="note_page"
              phx-value-page={@note_page - 1}
              class="text-sm text-gray-500 hover:text-gray-900 disabled:opacity-50"
              disabled={@note_page <= 1}
              id="notes-prev"
            >
              Prev
            </button>
            <button
              type="button"
              phx-click="note_page"
              phx-value-page={@note_page + 1}
              class="text-sm text-gray-500 hover:text-gray-900 disabled:opacity-50"
              disabled={@note_page >= @note_total_pages}
              id="notes-next"
            >
              Next
            </button>
          </div>

          <button
            type="button"
            phx-click="toggle_note_form"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-violet-600 dark:text-violet-400 hover:text-violet-500 transition-colors"
            id="note-add-trigger"
          >
            <.icon name={if @note_form_open?, do: "hero-x-mark", else: "hero-plus"} class="size-4" />
            {if @note_form_open?, do: "Cancel", else: "Add note"}
          </button>
        </div>

        <div
          id="note-form-wrapper"
          class={[
            "mt-3 rounded-xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-950/40 overflow-hidden",
            if(@note_form_open?, do: "", else: "hidden")
          ]}
        >
          <.form for={@note_form} id="note-quick-form" phx-submit="note_create">
            <div class="divide-y divide-gray-100 dark:divide-gray-800">
              <.field
                field={@note_form[:title]}
                type="text"
                label="Title"
                placeholder="Optional title…"
                wrapper_class="!mb-0 flex items-center gap-3 px-3 py-2"
                label_class="w-16 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400 !mb-0"
                class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600"
              />
              <div class="flex items-start gap-3 px-3 py-2">
                <label class="w-16 shrink-0 text-xs font-medium text-gray-500 dark:text-gray-400">
                  Body
                </label>
                <textarea
                  name={@note_form[:body].name}
                  id={@note_form[:body].id}
                  rows="1"
                  placeholder="Write your note…"
                  class="flex-1 bg-transparent border-0 outline-none shadow-none focus:ring-0 text-sm p-0 placeholder:text-gray-300 dark:placeholder:text-gray-600 resize-none text-gray-900 dark:text-white"
                >{Phoenix.HTML.Form.normalize_value("textarea", @note_form[:body].value)}</textarea>
                <button
                  type="submit"
                  phx-disable-with="Adding…"
                  class="shrink-0 self-end text-sm font-semibold text-violet-600 hover:text-violet-500 transition-colors disabled:opacity-50 border-l border-gray-200 dark:border-gray-700 pl-3"
                  id="note-quick-add"
                >
                  Add
                </button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
