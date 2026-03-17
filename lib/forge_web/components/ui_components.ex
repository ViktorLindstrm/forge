defmodule ForgeWeb.UIComponents do
  @moduledoc """
  Generiska UI-komponenter med Petal Components som bas.
  """
  use Phoenix.Component
  use PetalComponents
  import ForgeWeb.CoreComponents
  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # Card — vår egen, smalare profil än PC.card
  # ---------------------------------------------------------------------------

  attr :id,    :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def customcard(assigns) do
    ~H"""
    <div id={@id} class={["border border-zinc-200 rounded-xl overflow-hidden bg-white", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :title, required: true
  slot :right

  def card_header(assigns) do
    ~H"""
    <div class={["flex items-center justify-between px-4 py-2.5 bg-zinc-50 border-b border-zinc-100", @class]}>
      <div class="flex items-center gap-2 min-w-0 font-medium text-sm text-zinc-600">
        <%= render_slot(@title) %>
      </div>
      <div :if={@right != []} class="flex items-center gap-2 flex-shrink-0">
        <%= render_slot(@right) %>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card_body(assigns) do
    ~H"""
    <div class={["p-4", @class]}><%= render_slot(@inner_block) %></div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ccard_footer(assigns) do
    ~H"""
    <div class={["flex items-center justify-between px-4 py-2 bg-zinc-50 border-t border-zinc-100", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Section label
  # ---------------------------------------------------------------------------

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def section_label(assigns) do
    ~H"""
    <div class={["text-xs font-medium text-zinc-400 uppercase tracking-wide", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Toggle group — segmented submit-control, inget PC-ekvivalent
  # ---------------------------------------------------------------------------

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def toggle_group(assigns) do
    ~H"""
    <div class={["flex items-center gap-1 rounded-lg border border-zinc-200 bg-white p-0.5", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :rest,   :global
  slot :inner_block, required: true

  def toggle_item(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-all",
        @active && "bg-zinc-800 text-white" || "text-zinc-500 hover:text-zinc-700 hover:bg-zinc-50"
      ]}
      {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # ---------------------------------------------------------------------------
  # Status badges — wrappar PC.badge
  # ---------------------------------------------------------------------------

  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <.badge color={status_badge_color(@status)} variant="light" size="xs">
      <%= status_badge_label(@status) %>
    </.badge>
    """
  end

  attr :status, :atom, required: true

  def task_status_badge(assigns) do
    ~H"""
    <.badge color={task_badge_color(@status)} variant="light" size="xs">
      <%= task_badge_label(@status) %>
    </.badge>
    """
  end

  attr :priority, :atom, required: true

  def priority_badge(assigns) do
    ~H"""
    <.badge color={priority_color(@priority)} variant="light" size="xs">
      <%= priority_label(@priority) %>
    </.badge>
    """
  end

  # ---------------------------------------------------------------------------
  # Ghost button — wrappar PC.button
  # ---------------------------------------------------------------------------

  attr :class, :string, default: nil
  attr :rest,  :global
  slot :inner_block, required: true

  def ghost_button(assigns) do
    ~H"""
    <.button variant="outline" color="gray" size="xs" class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </.button>
    """
  end

  # ---------------------------------------------------------------------------
  # Dismiss button
  # ---------------------------------------------------------------------------

  attr :rest, :global

  def dismiss_button(assigns) do
    ~H"""
    <button class="text-zinc-300 hover:text-zinc-500 text-base leading-none" {@rest}>×</button>
    """
  end

  # ---------------------------------------------------------------------------
  # Dropzone — inget PC-ekvivalent
  # ---------------------------------------------------------------------------

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def dropzone(assigns) do
    ~H"""
    <div class={[
      "border-2 border-dashed border-zinc-200 rounded-lg px-3 py-4 text-center",
      "hover:border-zinc-300 transition-colors bg-white cursor-pointer",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Upload entry row — wrappar PC.progress
  # ---------------------------------------------------------------------------

  attr :entry, :map,    required: true
  attr :icon,  :string, default: "📎"

  def upload_entry_row(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-xs border border-zinc-100 rounded px-2 py-1.5 bg-white">
      <span style="font-size:13px"><%= @icon %></span>
      <span class="flex-1 truncate text-zinc-600"><%= @entry.client_name %></span>
      <div class="w-12">
        <.progress size="xs" value={@entry.progress} color="success" />
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Expandable panel
  # ---------------------------------------------------------------------------

  attr :id,    :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def expandable_panel(assigns) do
    ~H"""
    <div id={@id} class={["hidden border-t border-zinc-100 bg-zinc-50/50", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Stat cell — inget PC-ekvivalent
  # ---------------------------------------------------------------------------

  attr :value, :any,    required: true
  attr :label, :string, required: true

  def stat_cell(assigns) do
    ~H"""
    <div class="bg-zinc-50 border border-zinc-100 rounded-lg p-2.5 text-center">
      <div class="text-base font-medium text-zinc-800"><%= @value %></div>
      <div class="text-xs text-zinc-400 mt-0.5"><%= @label %></div>
    </div>
    """
  end

  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  slot :inner_block, required: true

  def crumb(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <%= if @navigate || @patch do %>
        <.link navigate={@navigate} patch={@patch} class="text-zinc-600 hover:text-zinc-900 transition-colors">
        <%= render_slot(@inner_block) %>
        </.link>
        <% else %>
        <span class="text-zinc-900"><%= render_slot(@inner_block) %></span>
        <% end %>
      <span class="text-zinc-300">/</span>
    </div>
    """
  end


  # ---------------------------------------------------------------------------
  # Privata helpers
  # ---------------------------------------------------------------------------

  defp status_badge_color(:active),    do: "success"
  defp status_badge_color(:idea),      do: "gray"
  defp status_badge_color(:on_hold),   do: "warning"
  defp status_badge_color(:done),      do: "success"
  defp status_badge_color(:abandoned), do: "danger"
  defp status_badge_color(_),          do: "gray"

  defp status_badge_label(:active),    do: "Aktiv"
  defp status_badge_label(:idea),      do: "Idé"
  defp status_badge_label(:on_hold),   do: "Pausad"
  defp status_badge_label(:done),      do: "Klar"
  defp status_badge_label(:abandoned), do: "Skrotad"
  defp status_badge_label(_),          do: "?"

  defp task_badge_color(:todo),        do: "gray"
  defp task_badge_color(:in_progress), do: "primary"
  defp task_badge_color(:blocked),     do: "danger"
  defp task_badge_color(:done),        do: "success"
  defp task_badge_color(_),            do: "gray"

  defp task_badge_label(:todo),        do: "Att göra"
  defp task_badge_label(:in_progress), do: "Pågår"
  defp task_badge_label(:blocked),     do: "Blockerad"
  defp task_badge_label(:done),        do: "Klar"
  defp task_badge_label(_),            do: "?"

  defp priority_color(:high),   do: "danger"
  defp priority_color(:medium), do: "warning"
  defp priority_color(:low),    do: "gray"
  defp priority_color(_),       do: "gray"

  defp priority_label(:high),   do: "Hög"
  defp priority_label(:medium), do: "Medium"
  defp priority_label(:low),    do: "Låg"
  defp priority_label(_),       do: "?"
end
