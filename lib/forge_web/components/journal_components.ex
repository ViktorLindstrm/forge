defmodule ForgeWeb.JournalComponents do
  use Phoenix.Component
  use ForgeWeb, :verified_routes
  use PetalComponents

  import ForgeWeb.CoreComponents
  import ForgeWeb.SharedHelpers
  import ForgeWeb.TaskComponents
  import ForgeWeb.UIComponents
  alias Phoenix.LiveView.JS
  alias Forge.BomParser

  # ---------------------------------------------------------------------------
  # Journal entry card
  # ---------------------------------------------------------------------------

  attr :entry,   :map,  required: true
  attr :tasks,   :list, required: true
  attr :uploads, :map,  required: true

  def journal_entry_card(assigns) do
    entry_tasks =
      Enum.filter(assigns.tasks, fn t ->
        t.journal_entry_id &&
          to_string(t.journal_entry_id) == to_string(assigns.entry.id)
      end)

    assigns =
      assigns
      |> assign(:segments, BomParser.parse(assigns.entry.body || ""))
      |> assign(:entry_tasks, entry_tasks)

    ~H"""
    <div class="relative pl-10 pb-4" id={"entry-#{@entry.id}"}>
      <div class="absolute left-[13px] top-5 w-2.5 h-2.5 rounded-full bg-zinc-300 border-2 border-white"></div>

      <.card>
        <.card_header>
          <:title>
            <span class="text-base select-none mr-1"><%= entry_icon(@entry) %></span>
            <span class="truncate"><%= @entry.title || "Loggpost" %></span>
          </:title>
          <:right>
            <span class="text-xs text-zinc-400">
              <%= Calendar.strftime(@entry.inserted_at, "%d %b %Y · %H:%M") %>
            </span>
          </:right>
        </.card_header>

        <.card_body class="space-y-3">
          <div :for={segment <- @segments}>
            <p :if={match?({:text, _}, segment) && elem(segment, 1) != ""}
               class="text-sm text-zinc-500 leading-relaxed whitespace-pre-wrap">
              <%= elem(segment, 1) %>
            </p>
            <.bom_block :if={match?({:bom, _}, segment)} items={elem(segment, 1)} />
          </div>
          <.task_entry_block
            :if={length(@entry_tasks) > 0}
            entry={@entry}
            entry_tasks={@entry_tasks} />
        </.card_body>

        <.ccard_footer>
          <.button phx-click={JS.toggle(to: "#edit-panel-#{@entry.id}")}
            variant="ghost" color="gray" size="xs">
            Redigera
          </.button>
          <.button phx-click="delete_entry" phx-value-id={@entry.id}
            data-confirm="Ta bort loggpost?"
            variant="ghost" color="danger" size="xs">
            Ta bort
          </.button>
        </.ccard_footer>

        <.expandable_panel id={"edit-panel-#{@entry.id}"}>
          <div class="p-4 space-y-4">
            <.entry_task_form entry={@entry} />
            <.entry_upload_form entry={@entry} uploads={@uploads} />
          </div>
        </.expandable_panel>
      </.card>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Entry task form
  # ---------------------------------------------------------------------------

  attr :entry, :map, required: true

  defp entry_task_form(assigns) do
    ~H"""
    <div>
      <.section_label class="mb-1.5">Lägg till task</.section_label>
      <form phx-submit="add_entry_task" class="flex gap-2 items-center">
        <input type="hidden" name="entry_id" value={@entry.id} />
        <input name="title" placeholder="Ny task till denna post..."
          class="flex-1 border border-zinc-200 rounded px-2 py-1.5 text-xs
                 outline-none focus:border-zinc-400 bg-white text-zinc-600" />
        <select name="status"
          class="text-xs border border-zinc-200 rounded px-1.5 py-1.5
                 bg-white text-zinc-500 outline-none">
          <option value="todo">Att göra</option>
          <option value="in_progress">Pågår</option>
          <option value="blocked">Blockerad</option>
        </select>
        <.button type="submit" variant="outline" color="gray" size="xs">
          + Task
        </.button>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Entry upload form
  # ---------------------------------------------------------------------------

  attr :entry,   :map, required: true
  attr :uploads, :map, required: true

  defp entry_upload_form(assigns) do
    ~H"""
    <div>
      <.section_label class="mb-1.5">Bifoga fil</.section_label>
      <form phx-submit="upload_attachment" phx-change="validate_upload" class="space-y-2">
        <input type="hidden" name="entry_id" value={@entry.id} />
        <div class="grid grid-cols-2 gap-2">
          <input name="title" placeholder="Titel"
            class="border border-zinc-200 rounded px-2 py-1.5 text-xs
                   outline-none focus:border-zinc-400 bg-white" />
          <.file_type_select />
        </div>
        <.dropzone>
          <label class="cursor-pointer">
            <div class="text-xs text-zinc-400">
              Dra & släpp eller <span class="text-zinc-600 underline">välj fil</span>
            </div>
            <.live_file_input upload={@uploads.attachment} class="sr-only" />
          </label>
        </.dropzone>
        <.upload_entry_row
          :for={entry <- @uploads.attachment.entries}
          entry={entry}
          icon={upload_icon(entry.client_type)} />
        <.button type="submit" color="gray" size="xs">
          <.icon name="hero-paper-clip" class="w-3 h-3" /> Ladda upp
        </.button>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # BOM block
  # ---------------------------------------------------------------------------

  attr :items, :list, required: true

  def bom_block(assigns) do
    received = Enum.count(assigns.items, & &1.done)
    total    = Enum.reduce(assigns.items, 0, fn i, acc ->
      case Integer.parse(i.price) do
        {n, _} -> acc + n
        :error  -> acc
      end
    end)
    pct = if length(assigns.items) > 0, do: round(received / length(assigns.items) * 100), else: 0
    assigns = assigns |> assign(:received, received) |> assign(:total, total) |> assign(:pct, pct)

    ~H"""
    <.card>
      <.card_header>
        <:title>
          <span class="font-mono text-xs text-zinc-400">:::bom</span>
        </:title>
        <:right>
          <div class="flex items-center gap-2 w-32">
            <.progress value={@pct} size="xs" color="success" />
            <span class="text-xs text-zinc-400 whitespace-nowrap">
              <%= @received %>/<%= length(@items) %>
            </span>
          </div>
        </:right>
      </.card_header>

      <div class="divide-y divide-zinc-100">
        <div :for={item <- @items}
          class={["flex items-center gap-3 px-3 py-2.5", item.done && "bg-zinc-50"]}>
          <div class={[
            "w-4 h-4 rounded border flex items-center justify-center flex-shrink-0",
            item.done && "bg-emerald-500 border-emerald-500" || "border-zinc-300"
          ]}>
            <svg :if={item.done} class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 10 8">
              <path d="M1 4l3 3 5-5" stroke="currentColor" stroke-width="1.5"
                stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <span class={["font-medium text-sm",
              item.done && "line-through text-zinc-400" || "text-zinc-700"]}>
              <%= item.name %>
            </span>
            <span class="text-zinc-400 ml-1 text-xs">×<%= item.qty %></span>
          </div>
          <span class="text-xs text-zinc-400 hidden sm:block truncate max-w-[120px]">
            <%= item.supplier %>
          </span>
          <span class={["text-xs font-mono whitespace-nowrap",
            item.done && "text-zinc-400" || "text-zinc-600"]}>
            <%= item.price %>
          </span>
        </div>
      </div>

      <.card_footer :if={@total > 0}>
        <span class="text-xs text-zinc-400">Totalt</span>
        <span class="text-xs font-mono font-medium text-zinc-600"><%= @total %> SEK</span>
      </.card_footer>
    </.card>
    """
  end

  # ---------------------------------------------------------------------------
  # Entry form
  # ---------------------------------------------------------------------------

  attr :project,     :map,     required: true
  attr :entry_form,  :map,     required: true
  attr :uploads,     :map,     required: true
  attr :mode,        :atom,    required: true
  attr :bom_rows,    :list,    required: true
  attr :show_bom,    :boolean, default: false
  attr :show_upload, :boolean, default: false

  def entry_form(assigns) do
    ~H"""
    <div class="border border-zinc-200 rounded-xl overflow-hidden mb-6 bg-white"
      id={"entry-form-wrap-#{@mode}-#{@show_bom}"}
      phx-update="replace">
      <form phx-submit="save_entry" phx-change="validate_entry" id="entry-form">

        <.card_header>
          <:title>Ny loggpost</:title>
          <:right>
            <.toggle_group>
              <.toggle_item type="submit" name="action" value="to_form" active={@mode == :form}>
                <.icon name="hero-pencil" class="w-3.5 h-3.5" />Skriv
              </.toggle_item>
              <.toggle_item type="submit" name="action" value="to_raw" active={@mode == :raw}>
                <.icon name="hero-code-bracket" class="w-3.5 h-3.5" />Markdown
              </.toggle_item>
            </.toggle_group>
          </:right>
        </.card_header>

        <.card_body class="space-y-3">

          <input name="entry[title]" value={@entry_form["title"]}
            placeholder="Rubrik (valfritt)"
            class="w-full border-0 border-b border-zinc-200 bg-transparent px-0 py-2
                   text-base font-medium outline-none focus:border-zinc-400
                   placeholder-zinc-300 text-zinc-800" />

          <%# SKRIV-LÄGE %>
          <div :if={@mode == :form} class="space-y-3">
            <textarea name="entry[text]" rows="6"
              placeholder="Vad hände? Anteckna fritt..."
              class="w-full border border-zinc-200 rounded-lg px-3 py-2.5 text-sm outline-none
                     focus:border-zinc-400 resize-y bg-zinc-50 text-zinc-700 leading-relaxed">
            </textarea>

            <.bom_builder :if={@show_bom} rows={@bom_rows} />
            <.upload_builder :if={@show_upload} uploads={@uploads} />

            <div class="flex items-center gap-2">
              <span class="text-xs text-zinc-300">Lägg till</span>
              <.ghost_button :if={!@show_bom}
                type="button" phx-click="show_entry_block" phx-value-block="bom">
                <.icon name="hero-squares-2x2" class="w-3.5 h-3.5" /> BOM
              </.ghost_button>
              <.ghost_button :if={!@show_upload}
                type="button" phx-click="show_entry_block" phx-value-block="upload">
                <.icon name="hero-photo" class="w-3.5 h-3.5" /> Bild
              </.ghost_button>
            </div>
          </div>

          <%# MARKDOWN-LÄGE %>
          <div :if={@mode == :raw}>
            <div phx-update="replace" id="entry-body-wrap">
              <textarea name="entry[body]" rows="14" id="entry-body-raw"
                placeholder={"Fri markdown.\n\n:::bom\n- [ ] Komponent ×1 | Leverantör | 99 SEK\n:::"}
                class="w-full border border-zinc-200 rounded-lg px-3 py-2.5 text-sm font-mono
                       outline-none focus:border-zinc-400 resize-y bg-zinc-50
                       text-zinc-700 leading-relaxed"><%= @entry_form["body"] %></textarea>
            </div>
          </div>

          <div class="flex items-center pt-2 border-t border-zinc-100">
            <div class="flex items-center gap-2">
              <.button type="submit" name="action" value="publish" color="gray">
                Publicera
              </.button>
              <.link patch={~p"/projects/#{@project.id}"}
                class="text-sm text-zinc-400 hover:text-zinc-600">
                Avbryt
              </.link>
            </div>
          </div>

        </.card_body>
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # BOM builder
  # ---------------------------------------------------------------------------

  attr :rows, :list, required: true

  defp bom_builder(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <:title>
          <.icon name="hero-squares-2x2" class="w-3.5 h-3.5 text-zinc-400" />
          BOM — komponenter
        </:title>
        <:right>
          <span class="text-xs font-mono text-zinc-300 bg-white px-1.5 py-0.5
                       rounded border border-zinc-100">:::bom</span>
          <.dismiss_button type="button" phx-click="hide_entry_block" phx-value-block="bom" />
        </:right>
      </.card_header>

      <.card_body>
        <p :if={@rows == []}
          class="text-xs text-zinc-400 italic py-2 text-center border border-dashed
                 border-zinc-200 rounded-lg bg-zinc-50/50">
          Inga komponenter ännu
        </p>

        <div :if={@rows != []}
          class="grid grid-cols-[1fr_56px_1fr_80px_28px] gap-2 px-1 mb-2">
          <span class="text-xs text-zinc-400">Namn</span>
          <span class="text-xs text-zinc-400">Antal</span>
          <span class="text-xs text-zinc-400">Leverantör</span>
          <span class="text-xs text-zinc-400">Pris</span>
          <span></span>
        </div>

        <div class="space-y-1.5">
          <.bom_form_row :for={{row, i} <- Enum.with_index(@rows)} row={row} index={i} />
        </div>

        <.button type="button" phx-click="add_bom_row"
          variant="outline" color="gray" size="xs" class="mt-2 w-full">
          <.icon name="hero-plus" class="w-3.5 h-3.5" /> Lägg till komponent
        </.button>
      </.card_body>
    </.card>
    """
  end

  # ---------------------------------------------------------------------------
  # BOM form row
  # ---------------------------------------------------------------------------

  attr :row,   :map,     required: true
  attr :index, :integer, required: true

  defp bom_form_row(assigns) do
    ~H"""
    <div class="grid grid-cols-[1fr_56px_1fr_80px_28px] gap-2 items-center
                bg-white border border-zinc-200 rounded-lg px-2 py-1.5
                hover:border-zinc-300 transition-colors">
      <div class="flex items-center gap-1.5 min-w-0">
        <input type="checkbox" name={"bom[#{@index}][done]"} value="true"
          checked={@row.done}
          class="w-3.5 h-3.5 rounded accent-emerald-500 flex-shrink-0" />
        <input name={"bom[#{@index}][name]"} value={@row.name} placeholder="Namn"
          class="flex-1 min-w-0 text-xs border-0 bg-transparent outline-none
                 text-zinc-700 placeholder-zinc-300" />
      </div>
      <input name={"bom[#{@index}][qty]"} value={@row.qty} type="number" min="1"
        class="text-xs border-0 bg-transparent outline-none text-zinc-700 text-center w-full" />
      <input name={"bom[#{@index}][supplier]"} value={@row.supplier} placeholder="Leverantör"
        class="text-xs border-0 bg-transparent outline-none text-zinc-700
               placeholder-zinc-300 min-w-0" />
      <input name={"bom[#{@index}][price]"} value={@row.price} placeholder="0 SEK"
        class="text-xs border-0 bg-transparent outline-none text-zinc-600
               placeholder-zinc-300 font-mono" />
      <.dismiss_button type="button" phx-click="remove_bom_row" phx-value-index={@index} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Upload builder
  # ---------------------------------------------------------------------------

  attr :uploads, :map, required: true

  defp upload_builder(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <:title>
          <.icon name="hero-photo" class="w-3.5 h-3.5 text-zinc-400" /> Bifoga bild
        </:title>
        <:right>
          <.dismiss_button type="button" phx-click="hide_entry_block" phx-value-block="upload" />
        </:right>
      </.card_header>
      <.card_body class="space-y-2">
        <div class="grid grid-cols-2 gap-2">
          <input name="attach_title" placeholder="Titel"
            class="border border-zinc-200 rounded px-2 py-1.5 text-xs
                   outline-none focus:border-zinc-400 bg-white" />
          <.file_type_select />
        </div>
        <.dropzone>
          <label class="cursor-pointer">
            <.icon name="hero-cloud-arrow-up" class="w-6 h-6 text-zinc-300 mx-auto mb-1" />
            <div class="text-xs text-zinc-400">
              Dra & släpp eller <span class="text-zinc-600 underline">välj fil</span>
            </div>
            <.live_file_input upload={@uploads.attachment} class="sr-only" />
          </label>
        </.dropzone>
        <.upload_entry_row
          :for={entry <- @uploads.attachment.entries}
          entry={entry}
          icon={upload_icon(entry.client_type)} />
      </.card_body>
    </.card>
    """
  end

  # ---------------------------------------------------------------------------
  # Shared
  # ---------------------------------------------------------------------------

  defp file_type_select(assigns) do
    ~H"""
    <select name="type"
      class="border border-zinc-200 rounded px-2 py-1.5 text-xs
             outline-none focus:border-zinc-400 bg-white text-zinc-500">
      <option value="image">Bild</option>
      <option value="model">Modell</option>
      <option value="config">Konfiguration</option>
      <option value="schematic">Ritning</option>
      <option value="document">Dokument</option>
      <option value="misc">Övrigt</option>
    </select>
    """
  end
end
