defmodule ForgeWeb.ProjectLive.Notes do
  @spec note_form() :: Phoenix.HTML.Form.t()
  def note_form do
    AshPhoenix.Form.for_create(Forge.Projects.JournalEntry, :create,
      domain: Forge.Projects,
      as: "note"
    )
    |> Phoenix.Component.to_form()
  end
end
