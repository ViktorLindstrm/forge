defmodule ForgeWeb.ProjectLive.NotesTest do
  use ExUnit.Case, async: true

  alias ForgeWeb.ProjectLive.Notes

  describe "note_form/0" do
    test "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :create" do
      form = Notes.note_form()
      assert %Phoenix.HTML.Form{} = form
      assert %AshPhoenix.Form{} = form.source
      assert form.source.resource == Forge.Projects.JournalEntry
      assert form.source.action == :create
      assert form.name == "note"
    end

    test "form does not include a title field" do
      form = Notes.note_form()
      fields = Enum.map(form.source.params || %{}, fn {k, _} -> k end)
      refute :title in fields
    end
  end
end
