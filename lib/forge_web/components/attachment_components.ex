defmodule ForgeWeb.AttachmentComponents do
  use Phoenix.Component
  use ForgeWeb, :verified_routes

  import ForgeWeb.CoreComponents
  import ForgeWeb.SharedHelpers

  attr :attachments, :list, required: true
  attr :uploads, :map, required: true
  attr :project, :map, required: true

  def attachment_section(assigns) do
    grouped = Enum.group_by(assigns.attachments, & &1.type)
    assigns = assign(assigns, :grouped, grouped)

    ~H"""
    <div class="mb-8">
      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-3">
        Bilagor · <%= length(@attachments) %> filer
      </div>
      <.attachment_group :if={Map.has_key?(@grouped, :image)}
        label="Bilder"          icon="hero-photo"              items={@grouped[:image]}     project={@project} />
      <.attachment_group :if={Map.has_key?(@grouped, :model)}
        label="Modeller"        icon="hero-cube"               items={@grouped[:model]}     project={@project} />
      <.attachment_group :if={Map.has_key?(@grouped, :config)}
        label="Konfigurationer" icon="hero-cog-6-tooth"        items={@grouped[:config]}    project={@project} />
      <.attachment_group :if={Map.has_key?(@grouped, :schematic)}
        label="Ritningar"       icon="hero-document-chart-bar" items={@grouped[:schematic]} project={@project} />
      <.attachment_group :if={Map.has_key?(@grouped, :document)}
        label="Dokument"        icon="hero-document-text"      items={@grouped[:document]}  project={@project} />
      <.attachment_group :if={Map.has_key?(@grouped, :misc)}
        label="Övrigt"          icon="hero-paper-clip"         items={@grouped[:misc]}      project={@project} />
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :items, :list, required: true
  attr :project, :map, required: true

  def attachment_group(assigns) do
    ~H"""
    <div class="border border-zinc-200 rounded-xl overflow-hidden mb-3 bg-white">
      <div class="flex items-center gap-2 px-4 py-2.5 bg-zinc-50 border-b border-zinc-100">
        <.icon name={@icon} class="w-4 h-4 text-zinc-400" />
        <span class="text-xs font-medium text-zinc-500"><%= @label %></span>
        <span class="text-xs text-zinc-300 ml-1"><%= length(@items) %></span>
      </div>

      <div :if={@label == "Bilder"} class="grid grid-cols-3 gap-2 p-3">
        <div :for={att <- @items} class="relative group">
          <img src={Forge.Storage.url(att.storage_path)} alt={att.title}
            class="w-full aspect-square object-cover rounded-lg border border-zinc-100" />
          <div class="absolute inset-0 bg-black/0 group-hover:bg-black/30 rounded-lg transition-all
                      flex items-end justify-between p-1.5 opacity-0 group-hover:opacity-100">
            <button phx-click="set_cover" phx-value-id={att.id}
              class="text-xs bg-white/90 px-2 py-0.5 rounded text-zinc-700 hover:bg-white">
              <%= if to_string(@project.cover_image_id) == to_string(att.id), do: "✓ Cover", else: "Cover" %>
            </button>
            <button phx-click="delete_attachment" phx-value-id={att.id} data-confirm="Ta bort?"
              class="text-xs bg-white/90 px-2 py-0.5 rounded text-red-500 hover:bg-white">
              ×
            </button>
          </div>
        </div>
      </div>

      <div :if={@label != "Bilder"} class="divide-y divide-zinc-50">
        <div :for={att <- @items}
          class="flex items-center gap-3 px-4 py-2.5 hover:bg-zinc-50 transition-colors">
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium text-zinc-700 truncate"><%= att.title %></div>
            <div class="text-xs text-zinc-400"><%= att.filename %></div>
          </div>
          <a href={Forge.Storage.url(att.storage_path)} target="_blank"
            class="text-xs text-zinc-400 hover:text-zinc-600 px-2 py-1 rounded
                   border border-zinc-200 hover:border-zinc-300">
            Öppna
          </a>
          <button phx-click="delete_attachment" phx-value-id={att.id} data-confirm="Ta bort?"
            class="text-xs text-zinc-300 hover:text-red-400 transition-colors">
            ×
          </button>
        </div>
      </div>
    </div>
    """
  end
end
