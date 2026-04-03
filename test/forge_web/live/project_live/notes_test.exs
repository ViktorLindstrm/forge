defmodule ForgeWeb.ProjectLive.NotesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ForgeWeb.ProjectLive.Notes

  describe "note_form/0" do
    property "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :create" do
      check all(_ <- constant(:ok)) do
        form = Notes.note_form()
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.JournalEntry
        assert form.source.action == :create
        assert form.name == "note"
      end
    end

    property "form does not include a title field in params" do
      check all(_ <- constant(:ok)) do
        form = Notes.note_form()
        fields = Enum.map(form.source.params || %{}, fn {k, _} -> k end)
        refute :title in fields
      end
    end
  end
end
