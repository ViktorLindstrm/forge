defmodule ForgeWeb.ProjectLive.NotesTest do
  use Forge.DataCase
  use ExUnitProperties

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Notes

  defp create_project! do
    {:ok, p} = Projects.create_project(%{"name" => "Notes #{System.unique_integer()}"})
    p
  end

  defp body_generator, do: string(:printable, min_length: 1, max_length: 200)
  defp title_generator, do: string(:printable, min_length: 1, max_length: 80)

  defp whitespace_generator do
    one_of([constant(""), constant("   "), constant("\t"), constant("\n")])
  end

  defp valid_params_generator do
    gen all(body <- body_generator()) do
      %{"note" => %{"body" => body, "title" => ""}}
    end
  end

  describe "handle_note_create/2" do
    property "creates a journal entry and returns stream reset" do
      check all(params <- valid_params_generator()) do
        project = create_project!()

        assert {:ok, result} = Notes.handle_note_create(params, project.id)
        assert is_list(result.assigns)
        assert Keyword.has_key?(result.assigns, :note_form)
        assert Keyword.has_key?(result.assigns, :notes_empty?)
        assert {:reset, :journal_entries, entries} = result.stream
        assert length(entries) == 1
      end
    end

    property "returns :blank_body error for whitespace-only body" do
      check all(ws <- whitespace_generator()) do
        project = create_project!()
        params = %{"note" => %{"body" => ws, "title" => ""}}

        assert {:error, :blank_body} = Notes.handle_note_create(params, project.id)
      end
    end

    property "title is stored when provided" do
      check all(body <- body_generator(), title <- title_generator()) do
        project = create_project!()
        params = %{"note" => %{"body" => body, "title" => title}}

        {:ok, _result} = Notes.handle_note_create(params, project.id)

        entry = Projects.list_journal_entries(project.id) |> List.first()
        assert entry.title == title
      end
    end

    property "nil title stored when title is blank" do
      check all(body <- body_generator()) do
        project = create_project!()
        params = %{"note" => %{"body" => body, "title" => "  "}}

        {:ok, _result} = Notes.handle_note_create(params, project.id)

        entry = Projects.list_journal_entries(project.id) |> List.first()
        assert is_nil(entry.title)
      end
    end

    property "note_form is reset to defaults after creation" do
      check all(params <- valid_params_generator()) do
        project = create_project!()

        {:ok, result} = Notes.handle_note_create(params, project.id)
        form = Keyword.get(result.assigns, :note_form)
        assert %Phoenix.HTML.Form{} = form
        assert form.params["body"] == ""
        assert form.params["title"] == ""
      end
    end

    property "notes_empty? is false after first entry" do
      check all(params <- valid_params_generator()) do
        project = create_project!()

        {:ok, result} = Notes.handle_note_create(params, project.id)
        assert Keyword.get(result.assigns, :notes_empty?) == false
      end
    end

    property "entries accumulate with each creation" do
      check all(bodies <- list_of(body_generator(), min_length: 2, max_length: 4)) do
        project = create_project!()

        Enum.each(bodies, fn body ->
          Notes.handle_note_create(%{"note" => %{"body" => body, "title" => ""}}, project.id)
        end)

        entries = Projects.list_journal_entries(project.id)
        assert length(entries) == length(bodies)
      end
    end
  end

  describe "handle_note_delete/2" do
    property "deletes entry and returns stream_delete" do
      check all(body <- body_generator()) do
        project = create_project!()

        {:ok, _} =
          Projects.create_journal_entry(%{"body" => body, "project_id" => project.id})

        entry = Projects.list_journal_entries(project.id) |> List.first()

        assert {:ok, result} = Notes.handle_note_delete(%{"id" => entry.id}, project.id)
        assert result.stream_delete == {:journal_entries, entry}
        assert_raise Ecto.NoResultsError, fn -> Projects.get_journal_entry!(entry.id) end
      end
    end

    property "notes_empty? is true after deleting the only entry" do
      check all(body <- body_generator()) do
        project = create_project!()

        {:ok, _} =
          Projects.create_journal_entry(%{"body" => body, "project_id" => project.id})

        entry = Projects.list_journal_entries(project.id) |> List.first()

        {:ok, result} = Notes.handle_note_delete(%{"id" => entry.id}, project.id)
        assert Keyword.get(result.assigns, :notes_empty?) == true
      end
    end
  end

  describe "note_form/0" do
    test "returns a Phoenix.HTML.Form with blank defaults" do
      form = Notes.note_form()
      assert %Phoenix.HTML.Form{} = form
      assert form.params["body"] == ""
      assert form.params["title"] == ""
    end
  end
end
