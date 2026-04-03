defmodule ForgeWeb.ProjectLive.NotePreviewTest do
  use ForgeWeb.ConnCase, async: true
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  defp create_project! do
    {:ok, project} =
      Projects.create_project(%{"name" => "Preview Test Project", "status" => "active"})

    project
  end

  defp type_and_preview(lv, body) do
    lv |> render_change("note_body_change", %{"note" => %{"body" => body}})
    lv |> render_click("note_preview_toggle", %{"tab" => "preview"})
  end

  describe "note creation preview — event handling" do
    property "switching to preview renders body content", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 1, max_length: 30),
              body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, body)

        html = render(lv)
        assert html =~ "note-preview-pane"
        assert html =~ word
      end
    end

    property "switching to preview with empty body shows dash placeholder", %{conn: conn} do
      check all(_ <- constant(:ok)) do
        project = create_project!()
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, "")

        html = render(lv)
        assert html =~ "—"
      end
    end

    property "preview never shows 'Nothing to preview' text for any input", %{conn: conn} do
      project = create_project!()

      check all(body <- string(:printable, min_length: 0, max_length: 100)) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, body)

        html = render(lv)
        refute html =~ "Nothing to preview"
      end
    end

    property "switching back to write tab hides the preview pane", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 1, max_length: 30),
              body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, body)
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})

        html = render(lv)
        assert html =~ "hidden"
      end
    end

    property "latest typed body is shown in preview", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 1, max_length: 30),
              body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, body)

        html = render(lv)
        assert html =~ word
      end
    end

    property "preview shows cleared body after write→clear→preview cycle", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 4, max_length: 30),
              initial_body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, initial_body)
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})
        type_and_preview(lv, "")

        html = render(lv)
        refute html =~ initial_body
        assert html =~ "—"
      end
    end

    property "toggle_note_form resets preview state and closes the form", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 1, max_length: 30),
              body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        lv |> render_click("toggle_note_form")
        type_and_preview(lv, body)
        lv |> render_click("toggle_note_form")

        html = render(lv)
        assert html =~ ~s(id="note-form-wrapper")
        assert html =~ "hidden"
      end
    end

    property "note_create resets preview state and closes the form", %{conn: conn} do
      project = create_project!()

      check all(
              word <- string(:alphanumeric, min_length: 1, max_length: 30),
              body = "PREVTEST_" <> word
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        lv |> render_click("toggle_note_form")
        type_and_preview(lv, body)

        lv
        |> form("#note-quick-form", note: %{body: body})
        |> render_submit()

        html = render(lv)
        assert html =~ ~s(id="note-form-wrapper")
        assert html =~ "hidden"
      end
    end
  end

  describe "note creation preview — property based" do
    property "any non-empty body shows content in preview pane", %{conn: conn} do
      project = create_project!()

      check all(
              body <-
                string(:printable, min_length: 1, max_length: 200)
                |> StreamData.filter(fn s ->
                  not String.contains?(s, ["<", ">", "&", "\""])
                end)
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, body)

        html = render(lv)
        assert html =~ "note-preview-pane"
        refute html =~ "Nothing to preview"
      end
    end

    property "empty body always shows dash, never stale content from prior preview", %{
      conn: conn
    } do
      project = create_project!()

      check all(
              unique_prefix <- string(:alphanumeric, min_length: 6, max_length: 10),
              suffix <- string(:alphanumeric, min_length: 6, max_length: 10),
              initial_body = "UNIQUEPREVIEWTEST_" <> unique_prefix <> "_" <> suffix
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        type_and_preview(lv, initial_body)
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})
        type_and_preview(lv, "")

        html = render(lv)
        refute html =~ initial_body
        assert html =~ "—"
      end
    end

    property "last typed body is reflected in preview when changed multiple times", %{
      conn: conn
    } do
      project = create_project!()

      check all(
              body1 <- string(:alphanumeric, min_length: 1, max_length: 50),
              body2 <-
                string(:alphanumeric, min_length: 1, max_length: 50)
                |> StreamData.filter(&(&1 != body1))
            ) do
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        lv |> render_change("note_body_change", %{"note" => %{"body" => body1}})
        lv |> render_change("note_body_change", %{"note" => %{"body" => body2}})
        lv |> render_click("note_preview_toggle", %{"tab" => "preview"})

        html = render(lv)
        assert html =~ body2
      end
    end
  end

  describe "full flow" do
    property "write markdown → preview renders HTML → back to write textarea contains original text → submit persists note",
             %{conn: conn} do
      check all(
              word <- string(:alphanumeric, min_length: 4, max_length: 20),
              body = "FLOWTEST_" <> word
            ) do
        project = create_project!()
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        # 1. Open the form
        lv |> render_click("toggle_note_form")

        # 2. Type text and switch to preview
        type_and_preview(lv, body)

        # 3. Preview must show the typed word
        preview_html = render(lv)

        assert preview_html =~ "note-preview-pane",
               "Expected to be in preview mode after clicking Preview"

        assert preview_html =~ word,
               "Expected preview to contain '#{word}' but it was missing"

        # 4. Switch back to write mode
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})
        write_html = render(lv)

        # 5. The textarea must still contain the typed text —
        #    this was the original bug: the textarea re-rendered empty
        assert write_html =~ body,
               "Expected textarea to still contain '#{body}' after returning to write mode, but it was gone"

        # 6. Submit and verify the note is persisted in both UI and DB
        lv
        |> form("#note-quick-form", note: %{body: body})
        |> render_submit()

        after_html = render(lv)

        assert after_html =~ word,
               "Expected note list to contain '#{word}' after submission"

        assert Projects.count_journal_entries(project.id) >= 1,
               "Expected at least one journal entry to exist in the database"
      end
    end

    property "write → preview → write preserves text across multiple preview toggles", %{
      conn: conn
    } do
      check all(
              word <- string(:alphanumeric, min_length: 4, max_length: 20),
              body = "TOGGLETEST_" <> word
            ) do
        project = create_project!()
        {:ok, lv, _html} = live(conn, ~p"/projects/#{project.id}")

        lv |> render_click("toggle_note_form")

        type_and_preview(lv, body)
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})

        assert render(lv) =~ body,
               "Text '#{body}' lost after first write→preview→write cycle"

        lv |> render_click("note_preview_toggle", %{"tab" => "preview"})
        lv |> render_click("note_preview_toggle", %{"tab" => "write"})

        assert render(lv) =~ body,
               "Text '#{body}' lost after second write→preview→write cycle"
      end
    end
  end
end
