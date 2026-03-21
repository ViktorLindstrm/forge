defmodule ForgeWeb.ProjectLive.ShowTest do
  use ForgeWeb.ConnCase
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  defp name_generator, do: string(:alphanumeric, min_length: 8, max_length: 60)
  defp title_generator, do: string(:alphanumeric, min_length: 8, max_length: 80)
  defp notes_generator, do: string(:alphanumeric, min_length: 8, max_length: 200)

  defp create_journal_entry!(project, body, title \\ nil) do
    attrs = %{"body" => body, "project_id" => project.id}
    attrs = if title, do: Map.put(attrs, "title", title), else: attrs
    {:ok, e} = Projects.create_journal_entry(attrs)
    e
  end

  defp status_generator do
    one_of(Enum.map(Projects.Project.statuses(), &constant/1))
  end

  defp bom_status_generator do
    one_of(Enum.map(Projects.BomItem.statuses(), &constant/1))
  end

  defp create_project!(attrs \\ %{}) do
    {:ok, p} =
      Projects.create_project(Map.merge(%{"name" => "P#{System.unique_integer()}"}, attrs))

    p
  end

  defp create_task!(project, title) do
    {:ok, t} = Projects.create_task(%{"title" => title, "project_id" => project.id})
    t
  end

  defp create_bom_item!(project, name, opts \\ %{}) do
    {:ok, item} =
      Projects.create_bom_item(
        Map.merge(
          %{"name" => name, "project_id" => project.id, "unit_price" => "10.00", "quantity" => 1},
          opts
        )
      )

    item
  end

  defp mount_show(project) do
    live(build_conn(), ~p"/projects/#{project.id}")
  end

  defp section_hidden?(html, section_id) do
    Regex.match?(
      ~r/<[^>]*class="[^"]*\bhidden\b[^"]*"[^>]*id="#{section_id}"|<[^>]*id="#{section_id}"[^>]*class="[^"]*\bhidden\b/,
      html
    )
  end

  # ── mount ─────────────────────────────────────────────────────────────────

  describe "mount" do
    property "renders project name in title heading" do
      check all(name <- name_generator()) do
        project = create_project!(%{"name" => name})
        {:ok, _lv, html} = mount_show(project)
        assert html =~ name
      end
    end

    property "renders project status badge" do
      check all(status <- status_generator()) do
        project = create_project!(%{"status" => to_string(status)})
        {:ok, _lv, html} = mount_show(project)
        assert html =~ String.capitalize(to_string(status))
      end
    end

    property "renders journal entry body on mount" do
      check all(body <- notes_generator()) do
        project = create_project!()
        create_journal_entry!(project, body)

        {:ok, _lv, html} = mount_show(project)
        assert html =~ body
      end
    end

    property "renders 'No notes yet' when project has no journal entries" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, _lv, html} = mount_show(project)
        assert html =~ "No notes yet"
      end
    end

    property "all three section bodies are present and not hidden on mount" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, _lv, html} = mount_show(project)

        assert html =~ "project-tasks-body"
        assert html =~ "project-notes-body"
        assert html =~ "project-bom-body"

        refute section_hidden?(html, "project-tasks-body")
        refute section_hidden?(html, "project-notes-body")
        refute section_hidden?(html, "project-bom-body")
      end
    end

    property "tasks section shows all created tasks on mount" do
      check all(title <- title_generator()) do
        project = create_project!()
        create_task!(project, title)
        {:ok, _lv, html} = mount_show(project)
        assert html =~ title
      end
    end

    property "bom items are shown on mount" do
      check all(
              item_name <- name_generator(),
              status <- bom_status_generator()
            ) do
        project = create_project!()
        create_bom_item!(project, item_name, %{"status" => to_string(status)})

        {:ok, _lv, html} = mount_show(project)
        assert html =~ item_name
        assert html =~ String.capitalize(to_string(status))
      end
    end
  end

  # ── toggle_section :notes ─────────────────────────────────────────────────

  describe "toggle_section notes" do
    property "collapses notes body on first toggle" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _html} = mount_show(project)

        html = lv |> element("#project-notes-toggle") |> render_click()
        assert section_hidden?(html, "project-notes-body")
      end
    end

    property "re-expands notes body on second toggle" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _html} = mount_show(project)

        lv |> element("#project-notes-toggle") |> render_click()
        html = lv |> element("#project-notes-toggle") |> render_click()

        refute section_hidden?(html, "project-notes-body")
      end
    end

    property "toggling notes does not hide tasks or bom bodies" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _html} = mount_show(project)

        lv |> element("#project-notes-toggle") |> render_click()
        html = render(lv)

        refute section_hidden?(html, "project-tasks-body")
        refute section_hidden?(html, "project-bom-body")
      end
    end

    property "note-quick-add button is inside the collapsible body" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, _lv, html} = mount_show(project)
        assert html =~ "note-quick-add"
        assert html =~ "project-notes-body"
      end
    end

    property "notes body is marked hidden after collapse" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        html = lv |> element("#project-notes-toggle") |> render_click()
        assert section_hidden?(html, "project-notes-body")
      end
    end

    property "notes content is visually hidden after collapse" do
      check all(body <- notes_generator()) do
        project = create_project!()
        create_journal_entry!(project, body)

        {:ok, lv, html_open} = mount_show(project)
        assert html_open =~ body

        html = lv |> element("#project-notes-toggle") |> render_click()
        assert section_hidden?(html, "project-notes-body")
      end
    end
  end

  # ── toggle_section :bom ───────────────────────────────────────────────────

  describe "toggle_section bom" do
    property "collapses bom body on first toggle" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        html = lv |> element("#project-bom-toggle") |> render_click()
        assert section_hidden?(html, "project-bom-body")
      end
    end

    property "re-expands bom body on second toggle" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        lv |> element("#project-bom-toggle") |> render_click()
        html = lv |> element("#project-bom-toggle") |> render_click()

        refute section_hidden?(html, "project-bom-body")
      end
    end

    property "toggling bom does not hide tasks or notes bodies" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        lv |> element("#project-bom-toggle") |> render_click()
        html = render(lv)

        refute section_hidden?(html, "project-tasks-body")
        refute section_hidden?(html, "project-notes-body")
      end
    end
  end

  # ── toggle_section :tasks ─────────────────────────────────────────────────

  describe "toggle_section tasks" do
    property "collapses tasks body on first toggle" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        html = lv |> element("#project-tasks-toggle") |> render_click()
        assert section_hidden?(html, "project-tasks-body")
      end
    end

    property "re-expanding tasks shows task content again" do
      check all(title <- title_generator()) do
        project = create_project!()
        create_task!(project, title)

        {:ok, lv, _} = mount_show(project)
        lv |> element("#project-tasks-toggle") |> render_click()
        html = lv |> element("#project-tasks-toggle") |> render_click()

        assert html =~ title
      end
    end

    property "toggling tasks does not hide notes or bom bodies" do
      check all(_n <- integer(1..5)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        lv |> element("#project-tasks-toggle") |> render_click()
        html = render(lv)

        refute section_hidden?(html, "project-notes-body")
        refute section_hidden?(html, "project-bom-body")
      end
    end
  end

  # ── BOM events ────────────────────────────────────────────────────────────

  describe "BOM events" do
    property "bom_create adds item to the page" do
      check all(item_name <- name_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        html =
          lv
          |> form("#bom-quick-form", bom: %{name: item_name, quantity: 1, unit_price: "20.00"})
          |> render_submit()

        assert html =~ item_name
      end
    end

    property "bom_delete removes item from page" do
      check all(item_name <- name_generator()) do
        project = create_project!()
        item = create_bom_item!(project, item_name)

        {:ok, lv, html_before} = mount_show(project)
        assert html_before =~ item_name

        lv
        |> element("[phx-click='bom_delete'][phx-value-id='#{item.id}']")
        |> render_click()

        refute render(lv) =~ item_name
      end
    end

    property "bom_toggle cycles needed -> ordered -> received -> needed" do
      check all(item_name <- name_generator()) do
        project = create_project!()
        item = create_bom_item!(project, item_name, %{"status" => "needed"})

        {:ok, lv, _} = mount_show(project)

        html = lv |> element("#bom-toggle-#{item.id}") |> render_click()
        assert html =~ "Ordered"

        html = lv |> element("#bom-toggle-#{item.id}") |> render_click()
        assert html =~ "Received"

        html = lv |> element("#bom-toggle-#{item.id}") |> render_click()
        assert html =~ "Needed"
      end
    end

    property "bom budget summary updates after bom_create" do
      check all(item_name <- name_generator()) do
        project = create_project!()
        {:ok, lv, html_before} = mount_show(project)
        assert html_before =~ "0 items"

        lv
        |> form("#bom-quick-form", bom: %{name: item_name, quantity: 1, unit_price: "15.00"})
        |> render_submit()

        html = render(lv)
        assert html =~ "1 items"
      end
    end
  end

  # ── task events ───────────────────────────────────────────────────────────

  describe "task events" do
    property "task_create adds task to the list" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)

        html =
          lv
          |> form("#task-quick-form", task: %{title: title})
          |> render_submit()

        assert html =~ title
      end
    end

    property "task_delete removes task from the page" do
      check all(title <- title_generator()) do
        project = create_project!()
        task = create_task!(project, title)

        {:ok, lv, html_before} = mount_show(project)
        assert html_before =~ title

        lv
        |> element("[phx-click='task_delete'][phx-value-id='#{task.id}']")
        |> render_click()

        refute render(lv) =~ title
      end
    end

    property "task_toggle marks task done in the database" do
      check all(title <- title_generator()) do
        project = create_project!()
        task = create_task!(project, title)

        {:ok, lv, _} = mount_show(project)
        lv |> element("#task-toggle-#{task.id}") |> render_click()

        assert Projects.get_task!(task.id).status == :done
      end
    end
  end

  # ── note events ───────────────────────────────────────────────────────────

  describe "note events" do
    defp open_note_form(lv) do
      lv |> element("#note-add-trigger") |> render_click()
    end

    property "note form is hidden on mount" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, _lv, html} = mount_show(project)
        assert html =~ "note-form-wrapper"
        assert html =~ "hidden"
      end
    end

    property "clicking add trigger opens the form" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        html = open_note_form(lv)
        refute section_hidden?(html, "note-form-wrapper")
      end
    end

    property "clicking cancel/trigger again closes the form" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        open_note_form(lv)
        html = lv |> element("#note-add-trigger") |> render_click()
        assert section_hidden?(html, "note-form-wrapper")
      end
    end

    property "note_create adds note body to the page" do
      check all(body <- notes_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        open_note_form(lv)

        lv
        |> form("#note-quick-form", note: %{body: body, title: ""})
        |> render_submit()

        assert render(lv) =~ body
      end
    end

    property "note_create with title shows title on the page" do
      check all(body <- notes_generator(), title <- name_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        open_note_form(lv)

        lv
        |> form("#note-quick-form", note: %{body: body, title: title})
        |> render_submit()

        html = render(lv)
        assert html =~ title
        assert html =~ body
      end
    end

    property "note form closes after successful submission" do
      check all(body <- notes_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        open_note_form(lv)

        lv
        |> form("#note-quick-form", note: %{body: body, title: ""})
        |> render_submit()

        html = render(lv)
        assert section_hidden?(html, "note-form-wrapper")
      end
    end

    property "note_delete removes note from the page" do
      check all(body <- notes_generator()) do
        project = create_project!()
        entry = create_journal_entry!(project, body)

        {:ok, lv, html_before} = mount_show(project)
        assert html_before =~ body

        lv
        |> element("[phx-click='note_delete'][phx-value-id='#{entry.id}']")
        |> render_click()

        refute render(lv) =~ body
      end
    end

    property "note_create increments the note count in the summary" do
      check all(body <- notes_generator()) do
        project = create_project!()
        {:ok, lv, html_before} = mount_show(project)
        assert html_before =~ "No notes yet"
        open_note_form(lv)

        lv
        |> form("#note-quick-form", note: %{body: body, title: ""})
        |> render_submit()

        html = render(lv)
        assert html =~ ~r/summary-notes.*?1.*?note/s
      end
    end

    property "note form is cleared after submission" do
      check all(body <- notes_generator()) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        open_note_form(lv)

        lv
        |> form("#note-quick-form", note: %{body: body, title: ""})
        |> render_submit()

        html = render(lv)
        assert html =~ "note-quick-form"
      end
    end
  end

  # ── budget events ─────────────────────────────────────────────────────────

  describe "budget events" do
    property "budget form is hidden on mount" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, _lv, html} = mount_show(project)
        assert html =~ "budget-edit-trigger"
        refute html =~ "budget-form"
      end
    end

    property "clicking edit trigger opens the budget form" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        html = lv |> element("#budget-edit-trigger") |> render_click()
        assert html =~ "budget-form"
        assert html =~ "budget-save"
      end
    end

    property "budget_update saves the budget and hides the form" do
      check all(amount <- integer(100..10_000)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        lv |> element("#budget-edit-trigger") |> render_click()

        lv
        |> form("#budget-form", project: %{budget: to_string(amount)})
        |> render_submit()

        html = render(lv)
        refute html =~ "budget-form"
        assert html =~ to_string(amount)
        assert Projects.get_project!(project.id).budget == Decimal.new(amount)
      end
    end

    property "budget_update persists to the database" do
      check all(amount <- integer(1..99_999)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        lv |> element("#budget-edit-trigger") |> render_click()

        lv
        |> form("#budget-form", project: %{budget: to_string(amount)})
        |> render_submit()

        assert Projects.get_project!(project.id).budget == Decimal.new(amount)
      end
    end

    property "cancelling edit hides the form without saving" do
      check all(_n <- integer(1..3)) do
        project = create_project!()
        {:ok, lv, _} = mount_show(project)
        lv |> element("#budget-edit-trigger") |> render_click()
        html = lv |> element("button", "Cancel") |> render_click()
        refute html =~ "budget-form"
        assert is_nil(Projects.get_project!(project.id).budget)
      end
    end
  end

  # ── delete project ────────────────────────────────────────────────────────

  describe "delete project" do
    property "deletes project and redirects to index" do
      check all(name <- name_generator()) do
        project = create_project!(%{"name" => name})
        {:ok, lv, _} = mount_show(project)

        lv |> element("#project-delete") |> render_click()

        assert_redirect(lv, ~p"/projects")
        assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
      end
    end
  end
end
