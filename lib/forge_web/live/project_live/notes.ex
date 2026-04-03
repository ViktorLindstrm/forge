defmodule ForgeWeb.ProjectLive.Notes do
  @moduledoc """
  Form-builder helpers for journal entry (note) LiveView interactions.

  Owns the `@notes_per_page` pagination constant so that the LiveView and any
  future consumers share a single source of truth rather than duplicating the
  value.
  """

  @notes_per_page 3

  @spec notes_per_page() :: pos_integer()
  def notes_per_page, do: @notes_per_page

  @spec note_form() :: Phoenix.HTML.Form.t()
  def note_form do
    AshPhoenix.Form.for_create(Forge.Projects.JournalEntry, :create,
      domain: Forge.Projects,
      as: "note"
    )
    |> Phoenix.Component.to_form()
  end

  @spec note_edit_form(Forge.Projects.JournalEntry.t()) :: Phoenix.HTML.Form.t()
  def note_edit_form(entry) do
    AshPhoenix.Form.for_update(entry, :update,
      domain: Forge.Projects,
      as: "note_edit"
    )
    |> Phoenix.Component.to_form()
  end
end
