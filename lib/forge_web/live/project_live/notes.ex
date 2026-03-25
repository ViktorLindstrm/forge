defmodule ForgeWeb.ProjectLive.Notes do
  alias Forge.Projects
  alias Forge.Projects.JournalEntry

  alias ForgeWeb.ProjectLive.Result

  @type project_id :: Projects.project_id()

  defdelegate list_journal_entries(project_id), to: Projects
  defdelegate create_journal_entry(attrs), to: Projects
  defdelegate delete_journal_entry(entry), to: Projects

  @spec handle_note_create(%{required(String.t()) => %{String.t() => String.t()}}, project_id()) ::
          Result.ok(JournalEntry.t()) | Result.error_changeset() | {:error, :blank_body}
  def handle_note_create(%{"note" => params}, project_id) do
    body = params |> Map.get("body", "") |> String.trim()

    if body == "" do
      {:error, :blank_body}
    else
      title =
        case params |> Map.get("title", "") |> String.trim() do
          "" -> nil
          t -> t
        end

      case create_journal_entry(%{
             "body" => body,
             "title" => title,
             "project_id" => project_id
           }) do
        {:ok, _entry} ->
          entries = list_journal_entries(project_id)

          {:ok,
           %{
             assigns: [
               note_form: note_form(),
               notes_empty?: entries == []
             ],
             stream: {:reset, :journal_entries, entries}
           }}

        {:error, changeset} ->
          {:error, {:changeset, changeset}}
      end
    end
  end

  @spec handle_note_delete(%{required(String.t()) => String.t()}, project_id()) ::
          Result.ok(JournalEntry.t())
  def handle_note_delete(%{"id" => id}, project_id) do
    entry = Projects.get_journal_entry!(id)
    {:ok, _} = delete_journal_entry(entry)

    entries = list_journal_entries(project_id)

    {:ok,
     %{
       assigns: [notes_empty?: entries == []],
       stream_delete: {:journal_entries, entry}
     }}
  end

  @spec note_form() :: Phoenix.HTML.Form.t()
  def note_form do
    AshPhoenix.Form.for_create(Forge.Projects.JournalEntry, :create,
      domain: Forge.Projects,
      as: "note"
    )
    |> Phoenix.Component.to_form()
  end
end
