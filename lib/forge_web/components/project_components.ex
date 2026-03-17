defmodule ForgeWeb.ProjectComponents do
  use Phoenix.Component
  use ForgeWeb, :verified_routes
  use PetalComponents

  import ForgeWeb.CoreComponents
  import ForgeWeb.SharedHelpers
  import ForgeWeb.TaskComponents
  import ForgeWeb.UIComponents
  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # Summary card
  # ---------------------------------------------------------------------------

  attr :project,      :map,  required: true
  attr :entries,      :list, required: true
  attr :tasks,        :list, required: true
  attr :project_tags, :list, required: true

  def project_summary_card(assigns) do
    ~H"""
    <div class="rounded-xl overflow-hidden mb-8 border border-zinc-200">
      <div class={["relative flex items-end px-5 pb-4 pt-10 min-h-[120px]", hero_bg(@project.category)]}>
        <div class="absolute inset-0 overflow-hidden">
          <img :if={cover_url(@project)} src={cover_url(@project)}
            class="w-full h-full object-cover opacity-40" />
        </div>
        <div class="absolute top-4 right-4 text-4xl select-none z-10">
          <%= @project.category && @project.category.icon || "📁" %>
        </div>
        <div class="flex items-center gap-2 relative z-10">
          <.status_badge status={@project.status} />
          <span :if={@project.category} class="text-xs text-white/70">
            <%= @project.category.name %>
          </span>
        </div>
      </div>

      <div class="bg-white px-5 py-4">
        <h1 class="text-lg font-medium mb-1"><%= @project.name %></h1>
        <p class="text-sm text-zinc-500 leading-relaxed mb-4">
          <%= @project.description || "Ingen beskrivning." %>
        </p>

        <%# BOM — kollapsbar %>
        <div class="mb-4">
          <button phx-click={JS.toggle(to: "#bom-detail-#{@project.id}")}
            class="flex items-center justify-between w-full group mb-2">
            <div class="flex items-center gap-2">
              <.section_label>BOM</.section_label>
              <span class="text-xs text-zinc-400">
                <%= bom_received(@project.bom_items) %>/<%= length(@project.bom_items) %> inköpta
                · <%= bom_total(@project.bom_items) %> kr
              </span>
            </div>
            <span class="text-xs text-zinc-300 group-hover:text-zinc-500 transition-colors">
              visa ▾
            </span>
          </button>

          <div id={"bom-detail-#{@project.id}"} class="hidden">
            <div class="grid grid-cols-3 gap-2 mb-3">
              <.stat_cell value={length(@project.bom_items)} label="BOM-rader" />
              <.stat_cell value={"#{bom_received(@project.bom_items)}/#{length(@project.bom_items)}"} label="Inköpta" />
              <.stat_cell value={"#{bom_total(@project.bom_items)} kr"} label="Totalt" />
            </div>
            <div class="border border-zinc-100 rounded-lg overflow-hidden divide-y divide-zinc-50">
              <div :for={item <- @project.bom_items}
                class={["flex items-center gap-3 px-3 py-2", item.status == :received && "bg-zinc-50/50"]}>
                <span class="flex-shrink-0">
                  <.icon name={bom_status_icon(item.status)}
                    class={"w-4 h-4 #{bom_status_icon_cls(item.status)}"} />
                </span>
                <span class={["flex-1 text-xs min-w-0 truncate",
                  item.status == :received && "line-through text-zinc-400" || "text-zinc-700"]}>
                  <%= item.name %>
                  <span class="text-zinc-400">×<%= item.quantity %></span>
                </span>
                <span class="text-xs text-zinc-400 hidden sm:block truncate max-w-[80px]">
                  <%= item.supplier %>
                </span>
                <span class="text-xs font-mono text-zinc-500 flex-shrink-0">
                  <%= if item.unit_price, do: "#{item.unit_price} kr", else: "–" %>
                </span>
                <.button phx-click="cycle_bom_status" phx-value-id={item.id}
                  variant="outline" size="xs"
                  class={"min-w-[90px] #{bom_status_btn_cls(item.status)}"}>
                  <%= bom_status_lbl(item.status) %>
                </.button>
              </div>
            </div>
          </div>
        </div>

        <%# Task-sektion %>
        <.task_section project={@project} tasks={@tasks} project_tags={@project_tags} />

        <div class="flex justify-between items-center pt-3 mt-3 border-t border-zinc-100">
          <div class="flex gap-2">
            <.button navigate={~p"/projects/#{@project.id}/entries/new"} color="gray">
              + Ny loggpost
            </.button>
            <.button patch={~p"/projects/#{@project.id}"} variant="outline" color="gray">
              Redigera
            </.button>
          </div>
          <.badge color="gray" variant="light">
            <%= length(@entries) %> loggposter
          </.badge>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp stat_cell(assigns) do
    ~H"""
    <div class="bg-zinc-50 border border-zinc-100 rounded-lg p-2.5 text-center">
      <div class="text-base font-medium text-zinc-800"><%= @value %></div>
      <div class="text-xs text-zinc-400 mt-0.5"><%= @label %></div>
    </div>
    """
  end

  defp cover_url(%{cover_image_id: nil}), do: nil
  defp cover_url(%{attachments: atts, cover_image_id: id}) when is_list(atts) do
    case Enum.find(atts, &(to_string(&1.id) == to_string(id))) do
      nil -> nil
      att -> Forge.Storage.url(att.storage_path)
    end
  end
  defp cover_url(_), do: nil

  defp hero_bg(nil),                    do: "bg-zinc-700"
  defp hero_bg(%{slug: "3d_printing"}), do: "bg-gradient-to-br from-orange-900 to-orange-700"
  defp hero_bg(%{slug: "programming"}), do: "bg-gradient-to-br from-indigo-900 to-indigo-700"
  defp hero_bg(%{slug: "electronics"}), do: "bg-gradient-to-br from-emerald-900 to-emerald-700"
  defp hero_bg(%{slug: "home"}),        do: "bg-gradient-to-br from-amber-900 to-amber-700"
  defp hero_bg(_),                      do: "bg-zinc-700"

  defp bom_status_btn_cls(:needed),     do: "text-zinc-500 border-zinc-200"
  defp bom_status_btn_cls(:ordered),    do: "text-blue-700 border-blue-200"
  defp bom_status_btn_cls(:received),   do: "text-emerald-700 border-emerald-200"
  defp bom_status_btn_cls(:not_needed), do: "text-zinc-400 border-zinc-200"
  defp bom_status_btn_cls(_),           do: "text-zinc-500 border-zinc-200"
end
