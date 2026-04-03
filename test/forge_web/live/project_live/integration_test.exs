defmodule ForgeWeb.ProjectLive.IntegrationTest do
  use ForgeWeb.ConnCase, async: true
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  @max_runs 10

  defp name_gen, do: string(:alphanumeric, min_length: 6, max_length: 60)
  defp title_gen, do: string(:alphanumeric, min_length: 4, max_length: 80)
  defp body_gen, do: string(:alphanumeric, min_length: 4, max_length: 200)
  defp amount_gen, do: integer(10..9_999)

  defp create_project!(opts \\ %{}) do
    {tasks_enabled, create_attrs} = Map.pop(opts, "tasks_enabled", true)

    {:ok, p} =
      Projects.create_project(Map.merge(%{"name" => "P#{System.unique_integer()}"}, create_attrs))

    if tasks_enabled do
      {:ok, p} = Projects.update_project(p, %{"tasks_enabled" => true})
      p
    else
      p
    end
  end

  defp create_bom_item!(project, name, extra) do
    {:ok, item} =
      Projects.create_bom_item(
        Map.merge(%{"name" => name, "project_id" => project.id, "quantity" => 1}, extra)
      )

    item
  end

  defp create_journal_entry!(project, body) do
    {:ok, e} = Projects.create_journal_entry(%{"body" => body, "project_id" => project.id})
    e
  end

  defp mount!(project) do
    live(build_conn(), ~p"/projects/#{project.id}")
  end

  # ── Tasks full flow ────────────────────────────────────────────────────────

  describe "full flow: tasks" do
    @tag timeout: 120_000
    property "create → pin current → complete → verify DB persisted" do
      check all(
              title <- title_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, _html} = mount!(project)

        lv |> element("#task-add-trigger") |> render_click()

        html =
          lv
          |> form("#task-quick-form", task: %{title: title})
          |> render_submit()

        assert html =~ title,
               "Task title '#{title}' not visible after creation"

        task = Projects.list_tasks(project.id) |> Enum.find(&(&1.title == title))
        assert task, "Task '#{title}' not found in database after creation"

        {:ok, _} = Projects.pin_task(task.id, :current)
        html = render(lv)

        assert html =~ "Current",
               "Current pin label missing after pin_task"

        assert html =~ title,
               "Task title '#{title}' missing after pinning"

        reloaded = Projects.get_task!(task.id)

        assert reloaded.pin_status == :current,
               "Expected pin_status :current in DB, got #{inspect(reloaded.pin_status)}"

        lv |> element("#task-toggle-#{task.id}") |> render_click()

        assert Projects.get_task!(task.id).status == :done,
               "Task should be :done in DB after toggle"

        html = render(lv)

        assert html =~ title,
               "Task title '#{title}' should still appear (done) after toggle"
      end
    end

    @tag timeout: 120_000
    property "create → edit → save → verify DB updated" do
      check all(
              title <- title_gen(),
              new_title <- title_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, _html} = mount!(project)

        lv |> element("#task-add-trigger") |> render_click()

        lv
        |> form("#task-quick-form", task: %{title: title})
        |> render_submit()

        task = Projects.list_tasks(project.id) |> Enum.find(&(&1.title == title))
        assert task, "Task '#{title}' not found after creation"

        lv |> element("#task-edit-#{task.id}") |> render_click()

        html =
          lv
          |> form("#task-edit-form-#{task.id}", task: %{title: new_title})
          |> render_submit()

        assert html =~ new_title,
               "Updated title '#{new_title}' not visible after edit save"

        assert Projects.get_task!(task.id).title == new_title,
               "Expected DB title '#{new_title}', got '#{Projects.get_task!(task.id).title}'"
      end
    end

    @tag timeout: 120_000
    property "create → delete → removed from page and DB" do
      check all(
              title <- title_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, _html} = mount!(project)

        lv |> element("#task-add-trigger") |> render_click()

        lv
        |> form("#task-quick-form", task: %{title: title})
        |> render_submit()

        task = Projects.list_tasks(project.id) |> Enum.find(&(&1.title == title))
        assert task, "Task '#{title}' not found after creation"

        lv
        |> element("[phx-click='task_delete'][phx-value-id='#{task.id}']")
        |> render_click()

        refute render(lv) =~ title,
               "Task title '#{title}' should be gone after deletion"

        assert_raise Ash.Error.Invalid, fn -> Projects.get_task!(task.id) end
      end
    end
  end

  # ── BOM full flow ──────────────────────────────────────────────────────────

  describe "full flow: BOM" do
    @tag timeout: 120_000
    property "create item → toggle status → edit name → delete → verify DB" do
      check all(
              item_name <- name_gen(),
              new_name <- name_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, _html} = mount!(project)

        lv |> element("#bom-add-trigger") |> render_click()

        html =
          lv
          |> form("#bom-quick-form", bom: %{name: item_name, quantity: 1, unit_price: "25.00"})
          |> render_submit()

        assert html =~ item_name,
               "BOM item '#{item_name}' not visible after creation"

        item = Projects.bom_budget(project.id).items |> Enum.find(&(&1.name == item_name))
        assert item, "BOM item '#{item_name}' not found in DB after creation"

        html = lv |> element("#bom-toggle-#{item.id}") |> render_click()

        assert html =~ "Ordered",
               "Expected status 'Ordered' after first toggle"

        assert Projects.get_bom_item!(item.id).status == :ordered,
               "Expected :ordered in DB after toggle"

        lv |> element("#bom-edit-#{item.id}") |> render_click()

        html =
          lv
          |> form("#bom-edit-form-#{item.id}", bom_edit: %{name: new_name, quantity: 1})
          |> render_submit()

        assert html =~ new_name,
               "Updated name '#{new_name}' not visible after edit"

        assert Projects.get_bom_item!(item.id).name == new_name,
               "Expected DB name '#{new_name}'"

        lv
        |> element("[phx-click='bom_delete'][phx-value-id='#{item.id}']")
        |> render_click()

        refute render(lv) =~ new_name,
               "BOM item '#{new_name}' should be gone after deletion"

        assert_raise Ash.Error.Invalid, fn -> Projects.get_bom_item!(item.id) end
      end
    end

    @tag timeout: 120_000
    property "bom budget display updates after item creation and status changes" do
      check all(
              item_name <- name_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, html_before} = mount!(project)

        assert html_before =~ "No items",
               "Expected 'No items' before any BOM items"

        lv |> element("#bom-add-trigger") |> render_click()

        lv
        |> form("#bom-quick-form", bom: %{name: item_name, quantity: 2, unit_price: "50.00"})
        |> render_submit()

        html = render(lv)

        assert html =~ "1 item",
               "Summary should show '1 item' after creation"

        item = Projects.bom_budget(project.id).items |> Enum.find(&(&1.name == item_name))
        lv |> element("#bom-toggle-#{item.id}") |> render_click()
        html = render(lv)

        assert html =~ "Ordered",
               "Status label should update to 'Ordered'"
      end
    end
  end

  # ── Budget full flow ───────────────────────────────────────────────────────

  describe "full flow: budget" do
    @tag timeout: 120_000
    property "set budget → displayed in header → update → persisted in DB" do
      check all(
              amount1 <- amount_gen(),
              amount2 <- amount_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, html_before} = mount!(project)

        assert html_before =~ "No budget set",
               "Expected 'No budget set' before any budget"

        lv |> element("#budget-edit-trigger") |> render_click()

        html =
          lv
          |> form("#budget-form", project: %{budget: to_string(amount1)})
          |> render_submit()

        assert html =~ to_string(amount1),
               "Budget #{amount1} not visible after first save"

        refute html =~ "budget-form",
               "Budget form should close after save"

        assert Projects.get_project!(project.id).budget == Decimal.new(amount1),
               "Budget #{amount1} not persisted in DB"

        lv |> element("#budget-edit-trigger") |> render_click()

        html =
          lv
          |> form("#budget-form", project: %{budget: to_string(amount2)})
          |> render_submit()

        assert html =~ to_string(amount2),
               "Updated budget #{amount2} not visible after second save"

        assert Projects.get_project!(project.id).budget == Decimal.new(amount2),
               "Updated budget #{amount2} not persisted in DB"
      end
    end

    @tag timeout: 120_000
    property "cancel budget edit does not change stored budget" do
      check all(
              amount <- amount_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        {:ok, lv, _} = mount!(project)

        lv |> element("#budget-edit-trigger") |> render_click()

        lv
        |> form("#budget-form", project: %{budget: to_string(amount)})
        |> render_submit()

        budget_after_first = Projects.get_project!(project.id).budget

        lv |> element("#budget-edit-trigger") |> render_click()
        lv |> element("#budget-cancel") |> render_click()

        html = render(lv)

        refute html =~ "budget-form",
               "Budget form should be closed after cancel"

        assert Projects.get_project!(project.id).budget == budget_after_first,
               "Budget should be unchanged after cancel"
      end
    end

    @tag timeout: 120_000
    property "bom spent amount shown in budget row when items are ordered" do
      check all(
              item_name <- name_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!()
        item = create_bom_item!(project, item_name, %{"unit_price" => "100.00", "quantity" => 1})
        {:ok, _} = Projects.update_bom_item(item, %{"status" => "ordered"})

        {:ok, _lv, html} = mount!(project)

        assert html =~ "spent",
               "Expected 'spent' label in budget row when items are ordered"
      end
    end
  end

  # ── Notes full flow ────────────────────────────────────────────────────────

  describe "full flow: notes" do
    @tag timeout: 120_000
    property "create note → edit → save → delete → all steps persist correctly" do
      check all(
              body1 <- body_gen(),
              body2 <- body_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(%{"tasks_enabled" => false})
        {:ok, lv, _html} = mount!(project)

        lv |> element("#note-add-trigger") |> render_click()

        html =
          lv
          |> form("#note-quick-form", note: %{body: body1})
          |> render_submit()

        assert html =~ body1,
               "Note body '#{body1}' not visible after creation"

        assert Projects.count_journal_entries(project.id) >= 1,
               "Note not found in DB after creation"

        entry =
          Projects.list_journal_entries(project.id)
          |> Enum.find(&String.contains?(&1.body, body1))

        assert entry, "Could not find created journal entry in DB"

        lv |> element("#note-edit-#{entry.id}") |> render_click()

        html =
          lv
          |> form("#note-edit-form-#{entry.id}", note_edit: %{body: body2})
          |> render_submit()

        assert html =~ body2,
               "Updated note body '#{body2}' not visible after edit"

        assert Projects.get_journal_entry!(entry.id).body == body2,
               "Note body '#{body2}' not persisted in DB"

        lv
        |> element("[phx-click='note_delete'][phx-value-id='#{entry.id}']")
        |> render_click()

        refute render(lv) =~ body2,
               "Note '#{body2}' should be gone after deletion"

        assert Projects.count_journal_entries(project.id) == 0,
               "Expected 0 journal entries after deletion"
      end
    end

    @tag timeout: 120_000
    property "pagination: page navigation loads correct entries" do
      check all(
              bodies <- list_of(body_gen(), min_length: 4, max_length: 6),
              max_runs: @max_runs
            ) do
        project = create_project!(%{"tasks_enabled" => false})
        entries = Enum.map(bodies, &create_journal_entry!(project, &1))
        per_page = ForgeWeb.ProjectLive.Notes.notes_per_page()

        {:ok, lv, html} = mount!(project)

        first_page_bodies = Enum.take(bodies |> Enum.reverse(), per_page)

        Enum.each(first_page_bodies, fn b ->
          assert html =~ b,
                 "Expected body '#{b}' on first page"
        end)

        remaining = length(entries) - per_page

        if remaining > 0 do
          html = lv |> element("#notes-next") |> render_click()

          last_page_body = bodies |> List.first()

          assert html =~ last_page_body,
                 "Expected body '#{last_page_body}' on second page"
        end
      end
    end
  end
end
