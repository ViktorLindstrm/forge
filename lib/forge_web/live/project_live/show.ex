defmodule ForgeWeb.ProjectLive.Show do
  use ForgeWeb, :live_view

  use PetalComponents
  import ForgeWeb.CoreComponents
  import ForgeWeb.ProjectComponents
  import ForgeWeb.TaskComponents
  import ForgeWeb.JournalComponents
  import ForgeWeb.AttachmentComponents

  alias Forge.{Project, JournalEntry, BomItem, Task, Tag, TaskTag}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    project = load_project(id)
    entries = JournalEntry.for_project!(id)

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:entries, entries)
     |> assign(:tasks, load_tasks(id))
     |> assign(:project_tags, Tag.for_project!(id))
     |> assign(:entry_form, blank_entry())
     |> assign(:entry_mode, :form)
     |> assign(:bom_rows, [])
     |> assign(:show_bom, false)
     |> assign(:show_upload, false)
     |> assign(:entry_text, "")
     |> assign(:attachments, load_attachments(id))
     |> allow_upload(:attachment,
          accept: ~w(.jpg .jpeg .png .gif .webp .pdf .yaml .yml .cfg .ini .stl .3mf .step),
          max_entries: 5,
          max_file_size: 50_000_000)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # ── Entry mode & blocks ───────────────────────────────────────────────────

  def handle_event("set_entry_mode", %{"mode" => "raw"}, socket) do
    markdown = form_to_markdown(
      %{"text" => socket.assigns.entry_text},
      socket.assigns.bom_rows
      |> Enum.with_index()
      |> Enum.into(%{}, fn {row, i} ->
        {to_string(i), Map.new(row, fn {k, v} -> {to_string(k), v} end)}
      end)
    )
    {:noreply,
     socket
     |> assign(:entry_mode, :raw)
     |> assign(:show_bom, false)
     |> assign(:show_upload, false)
     |> assign(:entry_form, Map.put(socket.assigns.entry_form, "body", markdown))}
  end

  def handle_event("set_entry_mode", %{"mode" => "form"}, socket) do
    {:noreply,
     socket
     |> assign(:entry_mode, :form)
     |> assign(:entry_form, Map.put(socket.assigns.entry_form, "body", ""))}
  end

  def handle_event("toggle_entry_block", %{"block" => "bom"}, socket) do
    {:noreply, assign(socket, :show_bom, !socket.assigns.show_bom)}
  end

  def handle_event("toggle_entry_block", %{"block" => "upload"}, socket) do
    {:noreply, assign(socket, :show_upload, !socket.assigns.show_upload)}
  end

  def handle_event("show_entry_block", %{"block" => "bom"}, socket) do
    {:noreply, assign(socket, :show_bom, true)}
  end

  def handle_event("show_entry_block", %{"block" => "upload"}, socket) do
    {:noreply, assign(socket, :show_upload, true)}
  end

  def handle_event("hide_entry_block", %{"block" => "bom"}, socket) do
    {:noreply, assign(socket, :show_bom, false)}
  end

  def handle_event("hide_entry_block", %{"block" => "upload"}, socket) do
    {:noreply, assign(socket, :show_upload, false)}
  end

  # ── BOM rows ──────────────────────────────────────────────────────────────

  def handle_event("add_bom_row", _params, socket) do
    row = %{name: "", qty: "1", supplier: "", price: "", done: false}
    {:noreply, assign(socket, :bom_rows, socket.assigns.bom_rows ++ [row])}
  end

  def handle_event("remove_bom_row", %{"index" => i}, socket) do
    rows = List.delete_at(socket.assigns.bom_rows, String.to_integer(i))
    {:noreply, assign(socket, :bom_rows, rows)}
  end

  # ── Tasks ─────────────────────────────────────────────────────────────────

  def handle_event("add_task", %{"title" => title, "priority" => priority}, socket) do
    title = String.trim(title)
    unless title == "" do
      Task.create!(%{
        title:      title,
        priority:   String.to_existing_atom(priority),
        project_id: socket.assigns.project.id,
        sort_order: length(socket.assigns.tasks)
      })
    end
    {:noreply, reload_tasks(socket)}
  end

  def handle_event("add_entry_task", %{"title" => title, "entry_id" => entry_id, "status" => status}, socket) do
    title = String.trim(title)
    unless title == "" do
      Task.create!(%{
        title:            title,
        status:           String.to_existing_atom(status),
        project_id:       socket.assigns.project.id,
        journal_entry_id: entry_id,
        sort_order:       length(socket.assigns.tasks)
      })
    end
    {:noreply, reload_tasks(socket)}
  end

  def handle_event("toggle_task", %{"id" => id}, socket) do
    find_task(socket, id) |> then(&if(&1, do: Task.toggle!(&1)))
    {:noreply, reload_tasks(socket)}
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    find_task(socket, id) |> then(&if(&1, do: Task.destroy!(&1)))
    {:noreply, reload_tasks(socket)}
  end

  def handle_event("reorder_tasks", %{"ids" => ids}, socket) do
    ids
    |> Enum.with_index()
    |> Enum.each(fn {id, index} ->
      find_task(socket, id) |> then(&if(&1, do: Task.reorder!(&1, %{sort_order: index})))
    end)
    {:noreply, reload_tasks(socket)}
  end

  def handle_event("update_task_tags", %{"task_id" => task_id, "tags" => tags_str}, socket) do
    task       = find_task(socket, task_id)
    project_id = socket.assigns.project.id

    if task do
      existing = Ash.load!(task, :tags).tags

      new_names =
        tags_str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.downcase/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()

      existing
      |> Enum.reject(&(&1.name in new_names))
      |> Enum.each(fn tag ->
        task_tag = Ash.get!(Forge.TaskTag, [task_id: task.id, tag_id: tag.id], domain: Forge.Domain)
        Forge.TaskTag.destroy!(task_tag)
      end)

      existing_names = Enum.map(existing, & &1.name)
      new_names
      |> Enum.reject(&(&1 in existing_names))
      |> Enum.each(fn name ->
        tag =
          case Ash.get(Forge.Tag, [name: name, project_id: project_id], domain: Forge.Domain) do
            {:ok, t} -> t
            _        -> Tag.create!(%{name: name, project_id: project_id})
          end
        TaskTag.create!(%{task_id: task.id, tag_id: tag.id})
      end)
    end

    {:noreply,
     socket
     |> reload_tasks()
     |> assign(:project_tags, Tag.for_project!(socket.assigns.project.id))}
  end

  # ── Journal entries ───────────────────────────────────────────────────────

  def handle_event("validate_entry", params, socket) do
    entry_text = get_in(params, ["entry", "text"]) || socket.assigns.entry_text

    socket =
      if socket.assigns.entry_mode == :form do
        bom_rows =
          (params["bom"] || %{})
          |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
          |> Enum.map(fn {_, row} ->
            %{
              name:     row["name"] || "",
              qty:      row["qty"] || "1",
              supplier: row["supplier"] || "",
              price:    row["price"] || "",
              done:     row["done"] == "true"
            }
          end)
        assign(socket, :bom_rows, bom_rows)
      else
        socket
      end

    {:noreply, assign(socket, :entry_text, entry_text)}
  end

  def handle_event("save_entry", %{"action" => "to_raw"} = all_params, socket) do
    text = get_in(all_params, ["entry", "text"]) || ""

    bom_rows =
      (all_params["bom"] || %{})
      |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
      |> Enum.map(fn {_, row} ->
        %{
          name:     row["name"] || "",
          qty:      row["qty"] || "1",
          supplier: row["supplier"] || "",
          price:    row["price"] || "",
          done:     row["done"] == "true"
        }
      end)

    markdown = form_to_markdown(%{"text" => text}, all_params["bom"])

    {:noreply,
     socket
     |> assign(:entry_mode, :raw)
     |> assign(:show_bom, false)
     |> assign(:show_upload, false)
     |> assign(:entry_text, text)
     |> assign(:bom_rows, bom_rows)
     |> assign(:entry_form, Map.put(socket.assigns.entry_form, "body", markdown))}
  end

  def handle_event("save_entry", %{"action" => "to_form"}, socket) do
    {:noreply,
     socket
     |> assign(:entry_mode, :form)
     |> assign(:entry_form, Map.put(socket.assigns.entry_form, "body", ""))}
  end

  def handle_event("save_entry", %{"entry" => params} = all_params, socket) do
    project_id = socket.assigns.project.id

    body =
      case socket.assigns.entry_mode do
        :raw  -> params["body"] || ""
        :form -> form_to_markdown(params, all_params["bom"])
      end

    entry_params = %{
      "title"      => params["title"],
      "body"       => body,
      "project_id" => project_id
    }

    case JournalEntry.create(entry_params) do
      {:ok, _} ->
        if socket.assigns.entry_mode == :form && socket.assigns.show_bom do
          existing_count = length(socket.assigns.project.bom_items)

          (all_params["bom"] || %{})
          |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
          |> Enum.map(fn {_, row} -> row end)
          |> Enum.reject(fn row -> String.trim(row["name"] || "") == "" end)
          |> Enum.with_index(existing_count)
          |> Enum.each(fn {row, i} ->
            price =
              case Float.parse(row["price"] || "") do
                {n, _} -> Decimal.from_float(n)
                :error  ->
                  case Integer.parse(row["price"] || "") do
                    {n, _} -> Decimal.new(n)
                    :error  -> nil
                  end
              end

            BomItem.create!(%{
              project_id: project_id,
              name:       String.trim(row["name"]),
              quantity:   String.to_integer(row["qty"] || "1"),
              supplier:   row["supplier"] || nil,
              unit_price: price,
              currency:   "SEK",
              status:     if(row["done"] == "true", do: :received, else: :needed),
              sort_order: i
            })
          end)
        end

        # Spara uppladdade filer om show_upload är aktiv
        if socket.assigns.show_upload do
          consume_uploaded_entries(socket, :attachment, fn %{path: tmp_path}, entry ->
            content  = File.read!(tmp_path)
            filename = Forge.Storage.unique_filename(entry.client_name)
            {:ok, storage_path} = Forge.Storage.store(filename, content)
            Forge.Attachment.create!(%{
              project_id:   project_id,
              type:         :image,
              title:        filename,
              filename:     entry.client_name,
              content_type: entry.client_type,
              storage_path: storage_path,
              size_bytes:   entry.client_size
            })
            {:ok, filename}
          end)
        end

        {:noreply,
         socket
         |> assign(:entries, JournalEntry.for_project!(project_id))
         |> assign(:entry_form, blank_entry())
         |> assign(:entry_mode, :form)
         |> assign(:bom_rows, [])
         |> assign(:show_bom, false)
         |> assign(:show_upload, false)
         |> assign(:entry_text, "")
         |> push_navigate(to: ~p"/projects/#{project_id}")}

      {:error, err} ->
        {:noreply, put_flash(socket, :error, inspect(err))}
    end
  end

  def handle_event("delete_entry", %{"id" => id}, socket) do
    socket.assigns.entries
    |> Enum.find(&(to_string(&1.id) == id))
    |> then(&if(&1, do: JournalEntry.destroy!(&1)))

    {:noreply,
     assign(socket, :entries, JournalEntry.for_project!(socket.assigns.project.id))}
  end

  # ── BOM ──────────────────────────────────────────────────────────────────

  def handle_event("cycle_bom_status", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.project.bom_items, &(to_string(&1.id) == id))
    if item do
      next = case item.status do
        :needed     -> :ordered
        :ordered    -> :received
        :received   -> :not_needed
        :not_needed -> :needed
        _           -> :needed
      end
      BomItem.update!(item, %{status: next})
    end
    {:noreply, assign(socket, :project, load_project(socket.assigns.project.id))}
  end

  def handle_event("toggle_bom_item", %{"id" => id}, socket) do
    socket.assigns.project.bom_items
    |> Enum.find(&(to_string(&1.id) == id))
    |> then(&if(&1, do: BomItem.toggle_received!(&1)))
    {:noreply, assign(socket, :project, load_project(socket.assigns.project.id))}
  end

  # ── Attachments ───────────────────────────────────────────────────────────

  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  def handle_event("upload_attachment", %{"title" => title, "type" => type}, socket) do
    project_id = socket.assigns.project.id

    uploaded =
      consume_uploaded_entries(socket, :attachment, fn %{path: tmp_path}, entry ->
        content  = File.read!(tmp_path)
        filename = Forge.Storage.unique_filename(entry.client_name)
        {:ok, storage_path} = Forge.Storage.store(filename, content)
        Forge.Attachment.create!(%{
          project_id:   project_id,
          type:         String.to_existing_atom(type),
          title:        title,
          filename:     entry.client_name,
          content_type: entry.client_type,
          storage_path: storage_path,
          size_bytes:   entry.client_size
        })
        {:ok, filename}
      end)

    if length(uploaded) > 0 do
      {:noreply,
       socket
       |> assign(:attachments, load_attachments(project_id))
       |> assign(:project, load_project(project_id))
       |> put_flash(:info, "#{length(uploaded)} fil(er) uppladdade")}
    else
      {:noreply, put_flash(socket, :error, "Ingen fil uppladdad")}
    end
  end

  def handle_event("set_cover", %{"id" => id}, socket) do
    Forge.Project.set_cover!(socket.assigns.project, id)
    {:noreply, assign(socket, :project, load_project(socket.assigns.project.id))}
  end

  def handle_event("delete_attachment", %{"id" => id}, socket) do
    att = Enum.find(socket.assigns.attachments, &(to_string(&1.id) == id))
    if att do
      Forge.Storage.delete(att.storage_path)
      Forge.Attachment.destroy!(att)
    end
    {:noreply, assign(socket, :attachments, load_attachments(socket.assigns.project.id))}
  end

  # Catch-all
  def handle_event(_, _params, socket), do: {:noreply, socket}

  # ── Private ───────────────────────────────────────────────────────────────

  defp load_project(id) do
    Project.get_by_id!(id,
      load: [
        :category,
        :journal_entries,
        bom_items: Forge.BomItem |> Ash.Query.sort(sort_order: :asc)
      ]
    )
  end

  defp load_tasks(project_id) do
    Task.for_project!(project_id) |> Ash.load!(:tags)
  end

  defp load_attachments(project_id), do: Forge.Attachment.for_project!(project_id)
  defp reload_tasks(socket), do: assign(socket, :tasks, load_tasks(socket.assigns.project.id))
  defp find_task(socket, id), do: Enum.find(socket.assigns.tasks, &(to_string(&1.id) == id))
  defp blank_entry, do: %{"title" => "", "body" => ""}

  defp form_to_markdown(params, bom_params) do
    sections = []

    sections =
      if params["text"] && String.trim(params["text"]) != "",
        do: sections ++ [String.trim(params["text"])],
        else: sections

    bom_rows =
      (bom_params || %{})
      |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
      |> Enum.map(fn {_, row} -> row end)
      |> Enum.reject(fn row -> String.trim(row["name"] || "") == "" end)

    sections =
      if bom_rows != [] do
        lines = Enum.map(bom_rows, fn row ->
          done  = row["done"] == "true"
          name  = String.trim(row["name"] || "")
          qty   = String.trim(row["qty"] || "1")
          sup   = if String.trim(row["supplier"] || "") == "", do: "–", else: String.trim(row["supplier"])
          price = if String.trim(row["price"] || "") == "", do: "–", else: String.trim(row["price"])
          mark  = if done, do: "x", else: " "
          "- [#{mark}] #{name} ×#{qty} | #{sup} | #{price}"
        end)
        sections ++ [":::bom\n#{Enum.join(lines, "\n")}\n:::"]
      else
        sections
      end

    Enum.join(sections, "\n\n")
  end

  # ── Render ────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <.breadcrumbs class="mb-4">
        <.crumb navigate={~p"/"}>Projekt</.crumb>
        <.crumb><%= @project.name %></.crumb>
      </.breadcrumbs>

      <.project_summary_card
        project={@project}
        entries={@entries}
        tasks={@tasks}
        project_tags={@project_tags}
      />

      <.entry_form
        :if={@live_action == :new_entry}
        project={@project}
        entry_form={@entry_form}
        uploads={@uploads}
        mode={@entry_mode}
        bom_rows={@bom_rows}
        show_bom={@show_bom}
        show_upload={@show_upload}
      />

      <div class="text-xs font-medium text-zinc-400 uppercase tracking-wide mb-3">
        Projektlogg · <%= length(@entries) %> poster
      </div>

      <div :if={@entries == []} class="text-sm text-zinc-400 italic py-4">
        Ingen logg ännu. Dags att skriva något.
      </div>

      <div class="relative">
        <div class="absolute left-4 top-0 bottom-0 w-px bg-zinc-100"></div>
        <.journal_entry_card
          :for={entry <- @entries}
          entry={entry}
          tasks={@tasks}
          uploads={@uploads}
        />
      </div>
    </div>
    """
  end
end
