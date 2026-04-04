defmodule ForgeWeb.ProjectLive.NoteHandlers do
  @moduledoc """
  Handles all note/journal-entry `handle_event` clauses for `ForgeWeb.ProjectLive.Show`.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [stream: 4, put_flash: 3]

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Notes

  @type socket :: Phoenix.LiveView.Socket.t()

  @spec toggle_note_form(map(), socket()) :: {:noreply, socket()}
  def toggle_note_form(_params, socket) do
    {:noreply,
     socket
     |> assign(:note_form_open?, !socket.assigns.note_form_open?)
     |> assign(:note_preview?, false)
     |> assign(:note_preview_body, "")}
  end

  @spec note_preview_toggle(map(), socket()) :: {:noreply, socket()}
  def note_preview_toggle(%{"tab" => "preview"}, socket) do
    body = socket.assigns.note_preview_body

    updated_form =
      AshPhoenix.Form.validate(socket.assigns.note_form.source, %{"body" => body})
      |> Phoenix.Component.to_form()

    {:noreply,
     socket
     |> assign(:note_preview?, true)
     |> assign(:note_form, updated_form)}
  end

  def note_preview_toggle(%{"tab" => "write"}, socket) do
    {:noreply, assign(socket, :note_preview?, false)}
  end

  @spec note_body_change(map(), socket()) :: {:noreply, socket()}
  def note_body_change(%{"note" => %{"body" => body}}, socket) do
    {:noreply, assign(socket, :note_preview_body, body)}
  end

  @spec note_create(map(), socket()) :: {:noreply, socket()}
  def note_create(%{"note" => params}, socket) do
    project_id = socket.assigns.project.id
    params = Map.put(params, "project_id", project_id)

    case AshPhoenix.Form.submit(socket.assigns.note_form.source, params: params) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> reload_notes(1)
         |> assign(:note_form, Notes.note_form())
         |> assign(:note_form_open?, false)
         |> assign(:note_preview?, false)
         |> assign(:note_preview_body, "")}

      {:error, form} ->
        {:noreply, assign(socket, :note_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec note_delete(map(), socket()) :: {:noreply, socket()}
  def note_delete(%{"id" => id}, socket) do
    entry = Projects.get_journal_entry!(id)

    case Projects.delete_journal_entry(entry) do
      {:ok, _} -> {:noreply, reload_notes(socket, socket.assigns.note_page)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete note.")}
    end
  end

  @spec note_edit_open(map(), socket()) :: {:noreply, socket()}
  def note_edit_open(%{"id" => id}, socket) do
    entry = Projects.get_journal_entry!(id)
    form = Notes.note_edit_form(entry)

    %{entries: entries} =
      Projects.list_journal_entries_page(
        socket.assigns.project.id,
        socket.assigns.note_page,
        Notes.notes_per_page()
      )

    {:noreply,
     socket
     |> assign(:editing_note_id, entry.id)
     |> assign(:note_edit_form, form)
     |> stream(:journal_entries, entries, reset: true)}
  end

  @spec note_edit_cancel(map(), socket()) :: {:noreply, socket()}
  def note_edit_cancel(_params, socket) do
    %{entries: entries} =
      Projects.list_journal_entries_page(
        socket.assigns.project.id,
        socket.assigns.note_page,
        Notes.notes_per_page()
      )

    {:noreply,
     socket
     |> assign(:editing_note_id, nil)
     |> assign(:note_edit_form, nil)
     |> stream(:journal_entries, entries, reset: true)}
  end

  @spec note_edit_save(map(), socket()) :: {:noreply, socket()}
  def note_edit_save(%{"note_edit" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.note_edit_form.source, params: params) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(:editing_note_id, nil)
         |> assign(:note_edit_form, nil)
         |> reload_notes(socket.assigns.note_page)}

      {:error, form} ->
        {:noreply, assign(socket, :note_edit_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec note_page(map(), socket()) :: {:noreply, socket()}
  def note_page(%{"page" => page_str}, socket) do
    page = page_str |> String.to_integer() |> max(1)
    {:noreply, reload_notes(socket, page)}
  end

  @spec reload_notes(socket(), pos_integer()) :: socket()
  def reload_notes(socket, page) do
    project_id = socket.assigns.project.id

    %{entries: entries, count: note_count} =
      Projects.list_journal_entries_page(project_id, page, Notes.notes_per_page())

    total_pages = Kernel.max(1, ceil(note_count / Notes.notes_per_page()))
    clamped_page = Kernel.min(page, total_pages)

    socket
    |> assign(:note_count, note_count)
    |> assign(:note_page, clamped_page)
    |> assign(:note_total_pages, total_pages)
    |> assign(:notes_empty?, entries == [])
    |> stream(:journal_entries, entries, reset: true)
  end
end
