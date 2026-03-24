defmodule Forge.ProjectsIntegrationTest do
  use Forge.DataCase
  use ExUnitProperties

  alias Forge.Projects
  alias Forge.Projects.{Project, Task}

  @max_runs 20

  defp project_name_gen, do: string(:alphanumeric, min_length: 1, max_length: 80)
  defp short_text_gen, do: string(:printable, min_length: 1, max_length: 100)
  defp body_gen, do: string(:printable, min_length: 1, max_length: 500)

  defp status_gen do
    one_of(Enum.map(Project.statuses(), &constant/1))
  end

  defp task_status_gen do
    one_of(Enum.map([:todo, :in_progress, :blocked], &constant/1))
  end

  defp priority_gen do
    one_of(Enum.map(Task.priorities(), &constant/1))
  end

  defp positive_integer_gen do
    integer(1..100)
  end

  defp decimal_price_gen do
    map(integer(0..9999), fn n -> Decimal.new(n) end)
  end

  defp create_project!(name, status \\ :idea) do
    {:ok, p} =
      Projects.create_project(%{"name" => name, "status" => to_string(status)})

    p
  end

  defp create_task!(project_id, title) do
    {:ok, t} = Projects.create_task(%{"title" => title, "project_id" => project_id})
    t
  end

  defp create_bom_item!(project_id, name) do
    {:ok, b} = Projects.create_bom_item(%{"name" => name, "project_id" => project_id})
    b
  end

  defp create_journal_entry!(project_id, body) do
    {:ok, j} = Projects.create_journal_entry(%{"body" => body, "project_id" => project_id})
    j
  end

  describe "project lifecycle: create → update status → delete" do
    @tag timeout: 60_000
    property "project moves through statuses and is deleted cleanly" do
      check all(
              name <- project_name_gen(),
              statuses <- list_of(status_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        {:ok, project} = Projects.create_project(%{"name" => name})
        assert project.status == :idea

        final =
          Enum.reduce(statuses, project, fn status, current ->
            {:ok, updated} =
              Projects.update_project(current, %{"status" => to_string(status)})

            assert updated.status == status
            assert updated.id == current.id
            updated
          end)

        {:ok, _} = Projects.delete_project(final)

        assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(final.id) end
      end
    end
  end

  describe "project group assignment flow" do
    @tag timeout: 60_000
    property "project can be assigned and reassigned to groups, then ungrouped" do
      check all(
              project_name <- project_name_gen(),
              group1_name <-
                map(string(:alphanumeric, min_length: 4, max_length: 30), &("G1_" <> &1)),
              group2_name <-
                map(string(:alphanumeric, min_length: 4, max_length: 30), &("G2_" <> &1)),
              max_runs: @max_runs
            ) do
        {:ok, g1} = Projects.create_project_group(%{"name" => group1_name})
        {:ok, g2} = Projects.create_project_group(%{"name" => group2_name})
        {:ok, project} = Projects.create_project(%{"name" => project_name})

        {:ok, assigned} = Projects.update_project(project, %{"project_group_id" => g1.id})
        assert assigned.project_group_id == g1.id

        {:ok, reassigned} = Projects.update_project(assigned, %{"project_group_id" => g2.id})
        assert reassigned.project_group_id == g2.id

        {:ok, ungrouped} = Projects.update_project(reassigned, %{"project_group_id" => nil})
        assert ungrouped.project_group_id == nil

        Projects.delete_project(ungrouped)
        Projects.delete_project_group(g1)
        Projects.delete_project_group(g2)
      end
    end

    @tag timeout: 60_000
    property "list_projects_grouped correctly places projects" do
      check all(
              project_name <- project_name_gen(),
              group_name <-
                map(string(:alphanumeric, min_length: 4, max_length: 30), &("GRP_" <> &1)),
              max_runs: @max_runs
            ) do
        {:ok, group} = Projects.create_project_group(%{"name" => group_name})
        {:ok, project} = Projects.create_project(%{"name" => project_name})

        {:ok, _} = Projects.update_project(project, %{"project_group_id" => group.id})

        grouped = Projects.list_projects_grouped()

        group_entry = Enum.find(grouped, fn {g, _} -> g != nil and g.id == group.id end)
        assert group_entry != nil, "Group should appear in grouped listing"
        {_, group_projects} = group_entry
        assert Enum.any?(group_projects, fn p -> p.name == project_name end)
      end
    end
  end

  describe "task lifecycle within project" do
    @tag timeout: 60_000
    property "tasks are created, updated, reordered, then deleted" do
      check all(
              project_name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 2, max_length: 5),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        tasks =
          Enum.map(titles, fn title ->
            create_task!(project.id, title)
          end)

        ids = Enum.map(tasks, & &1.id)
        reversed = Enum.reverse(ids)

        :ok = Projects.reorder_tasks(project.id, reversed)

        reordered = Projects.list_tasks(project.id)
        assert Enum.map(reordered, & &1.id) == reversed

        Enum.each(reordered, fn task ->
          {:ok, _} = Projects.delete_task(task)
        end)

        assert Projects.list_tasks(project.id) == []
      end
    end

    @tag timeout: 60_000
    property "task status transitions are reflected in task_stats" do
      check all(
              project_name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        tasks = Enum.map(titles, &create_task!(project.id, &1))

        stats_before = Projects.task_stats(project.id)
        todo_before = Map.get(stats_before, :todo, 0)
        assert todo_before == length(tasks)

        to_complete = Enum.take(tasks, div(length(tasks), 2) + 1)

        Enum.each(to_complete, fn task ->
          {:ok, done} = Projects.toggle_task_done(task)
          assert done.status == :done
        end)

        stats_after = Projects.task_stats(project.id)
        assert Map.get(stats_after, :done, 0) == length(to_complete)
        assert Map.get(stats_after, :todo, 0) == length(tasks) - length(to_complete)
      end
    end

    @tag timeout: 60_000
    property "update task priority and status through multiple changes" do
      check all(
              project_name <- project_name_gen(),
              title <- short_text_gen(),
              priority1 <- priority_gen(),
              priority2 <- priority_gen(),
              status <- task_status_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)
        task = create_task!(project.id, title)

        {:ok, t1} = Projects.update_task(task, %{priority: priority1})
        assert t1.priority == priority1

        {:ok, t2} = Projects.update_task(t1, %{priority: priority2})
        assert t2.priority == priority2

        {:ok, t3} = Projects.update_task(t2, %{status: status})
        assert t3.status == status

        fetched = Projects.get_task!(task.id)
        assert fetched.priority == priority2
        assert fetched.status == status
      end
    end
  end

  describe "subtask hierarchy flow" do
    @tag timeout: 60_000
    property "parent task cascades done to subtasks" do
      check all(
              project_name <- project_name_gen(),
              parent_title <- short_text_gen(),
              sub_titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        {:ok, parent} =
          Projects.create_task(%{"title" => parent_title, "project_id" => project.id})

        subtasks =
          Enum.map(sub_titles, fn title ->
            {:ok, sub} =
              Projects.create_task(%{
                "title" => title,
                "project_id" => project.id,
                "parent_task_id" => parent.id
              })

            sub
          end)

        {:ok, done_parent} = Projects.toggle_task_done(parent)
        assert done_parent.status == :done

        reloaded_subs = Enum.map(subtasks, fn s -> Projects.get_task!(s.id) end)
        assert Enum.all?(reloaded_subs, &(&1.status == :done))
      end
    end

    @tag timeout: 60_000
    property "all subtasks done causes parent to become done" do
      check all(
              project_name <- project_name_gen(),
              parent_title <- short_text_gen(),
              sub_titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        {:ok, parent} =
          Projects.create_task(%{"title" => parent_title, "project_id" => project.id})

        subtasks =
          Enum.map(sub_titles, fn title ->
            {:ok, sub} =
              Projects.create_task(%{
                "title" => title,
                "project_id" => project.id,
                "parent_task_id" => parent.id
              })

            sub
          end)

        Enum.each(subtasks, fn sub ->
          {:ok, _} = Projects.toggle_task_done(sub)
        end)

        reloaded_parent = Projects.get_task!(parent.id)
        assert reloaded_parent.status == :done
      end
    end

    @tag timeout: 60_000
    property "reorder_subtasks respects parent boundary" do
      check all(
              project_name <- project_name_gen(),
              parent_title <- short_text_gen(),
              sub_titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        {:ok, parent} =
          Projects.create_task(%{"title" => parent_title, "project_id" => project.id})

        subtasks =
          Enum.map(sub_titles, fn title ->
            {:ok, sub} =
              Projects.create_task(%{
                "title" => title,
                "project_id" => project.id,
                "parent_task_id" => parent.id
              })

            sub
          end)

        sub_ids = Enum.map(subtasks, & &1.id)
        reversed = Enum.reverse(sub_ids)

        :ok = Projects.reorder_subtasks(parent.id, reversed)

        reordered = Projects.list_subtasks(parent.id)
        assert Enum.map(reordered, & &1.id) == reversed
        assert Enum.map(reordered, & &1.sort_order) == Enum.to_list(1..length(reversed))
      end
    end
  end

  describe "pin workflow integration" do
    @tag timeout: 120_000
    property "current/upcoming pins are managed across task lifecycle" do
      check all(
              project_name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 3, max_length: 5),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)
        tasks = Enum.map(titles, &create_task!(project.id, &1))

        [t1, t2, t3 | _rest] = tasks

        {:ok, _} = Projects.pin_task(t1.id, :current)
        {:ok, _} = Projects.pin_task(t2.id, :upcoming)

        check_pins = Projects.list_tasks(project.id)
        assert Enum.count(check_pins, &(&1.pin_status == :current)) == 1
        assert Enum.count(check_pins, &(&1.pin_status == :upcoming)) == 1

        {:ok, _} = Projects.pin_task(t3.id, :current)

        after_repins = Projects.list_tasks(project.id)
        assert Enum.count(after_repins, &(&1.pin_status == :current)) == 1
        assert Enum.any?(after_repins, &(&1.id == t3.id and &1.pin_status == :current))
        refute Enum.any?(after_repins, &(&1.id == t1.id and &1.pin_status == :current))

        {:ok, _} = Projects.unpin_task(t3.id)

        after_unpin = Projects.list_tasks(project.id)
        assert Enum.all?(after_unpin, &(&1.pin_status != :current))
      end
    end

    @tag timeout: 60_000
    property "completing a pinned task clears pin and maintains list correctness" do
      check all(
              project_name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)
        tasks = Enum.map(titles, &create_task!(project.id, &1))

        [current_task, upcoming_task | _] = tasks

        {:ok, _} = Projects.pin_task(current_task.id, :current)
        {:ok, _} = Projects.pin_task(upcoming_task.id, :upcoming)

        reloaded_current = Projects.get_task!(current_task.id)
        {:ok, done_current} = Projects.toggle_task_done(reloaded_current)
        assert done_current.pin_status == nil
        assert done_current.status == :done

        pinned_after = Projects.list_tasks(project.id)
        assert Enum.count(pinned_after, &(&1.pin_status == :current)) == 0
        assert Enum.count(pinned_after, &(&1.pin_status == :upcoming)) == 1
      end
    end
  end

  describe "BOM item flow" do
    @tag timeout: 60_000
    property "bom items cycle through statuses and budget is reflected correctly" do
      check all(
              project_name <- project_name_gen(),
              item_names <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              prices <- list_of(decimal_price_gen(), length: 4),
              qtys <- list_of(positive_integer_gen(), length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        items =
          item_names
          |> Enum.with_index()
          |> Enum.map(fn {name, i} ->
            price = Enum.at(prices, i)
            qty = Enum.at(qtys, i)

            {:ok, item} =
              Projects.create_bom_item(%{
                "name" => name,
                "project_id" => project.id,
                "unit_price" => price,
                "quantity" => qty
              })

            item
          end)

        budget_initial = Projects.bom_budget(project.id)
        assert Decimal.compare(budget_initial.spent, Decimal.new(0)) == :eq

        expected_total =
          Enum.reduce(items, Decimal.new(0), fn item, acc ->
            Decimal.add(
              acc,
              Decimal.mult(item.unit_price || Decimal.new(0), Decimal.new(item.quantity))
            )
          end)

        assert Decimal.compare(budget_initial.total, expected_total) == :eq

        [item1, item2 | _] = items
        {:ok, _} = Projects.update_bom_item(item1, %{"status" => "ordered"})
        {:ok, _} = Projects.update_bom_item(item2, %{"status" => "received"})

        budget_after = Projects.bom_budget(project.id)
        spent_items = [item1, item2]

        expected_spent =
          Enum.reduce(spent_items, Decimal.new(0), fn item, acc ->
            Decimal.add(
              acc,
              Decimal.mult(item.unit_price || Decimal.new(0), Decimal.new(item.quantity))
            )
          end)

        assert Decimal.compare(budget_after.spent, expected_spent) == :eq
      end
    end

    @tag timeout: 60_000
    property "deleting a bom item removes it from budget" do
      check all(
              project_name <- project_name_gen(),
              item_name <- short_text_gen(),
              price <- decimal_price_gen(),
              qty <- positive_integer_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        {:ok, item} =
          Projects.create_bom_item(%{
            "name" => item_name,
            "project_id" => project.id,
            "unit_price" => price,
            "quantity" => qty
          })

        budget_with = Projects.bom_budget(project.id)
        expected = Decimal.mult(price, Decimal.new(qty))
        assert Decimal.compare(budget_with.total, expected) in [:eq, :gt]

        {:ok, _} = Projects.delete_bom_item(item)

        budget_without = Projects.bom_budget(project.id)
        assert Decimal.compare(budget_without.total, budget_with.total) in [:lt, :eq]
      end
    end
  end

  describe "journal entry flow" do
    @tag timeout: 60_000
    property "journal entries have incrementing sort_order and paginate correctly" do
      check all(
              project_name <- project_name_gen(),
              bodies <- list_of(body_gen(), min_length: 3, max_length: 6),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        entries =
          Enum.map(bodies, fn body ->
            {:ok, e} =
              Projects.create_journal_entry(%{"body" => body, "project_id" => project.id})

            e
          end)

        sort_orders = Enum.map(entries, & &1.sort_order)
        assert sort_orders == Enum.sort(sort_orders)
        assert length(Enum.uniq(sort_orders)) == length(sort_orders)

        total = Projects.count_journal_entries(project.id)
        assert total >= length(bodies)

        page1 = Projects.list_journal_entries_page(project.id, 1, 2)
        page2 = Projects.list_journal_entries_page(project.id, 2, 2)

        assert length(page1) == 2
        page1_ids = MapSet.new(page1, & &1.id)
        page2_ids = MapSet.new(page2, & &1.id)
        assert MapSet.disjoint?(page1_ids, page2_ids)
      end
    end

    @tag timeout: 60_000
    property "journal entry update preserves project association" do
      check all(
              project_name <- project_name_gen(),
              body1 <- body_gen(),
              body2 <- body_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        {:ok, entry} =
          Projects.create_journal_entry(%{"body" => body1, "project_id" => project.id})

        assert entry.project_id == project.id

        {:ok, updated} = Projects.update_journal_entry(entry, %{"body" => body2})
        assert updated.body == body2
        assert updated.project_id == project.id
        assert updated.id == entry.id

        fetched = Projects.get_journal_entry!(entry.id)
        assert fetched.body == body2
      end
    end
  end

  describe "full project teardown: cascade delete" do
    @tag timeout: 120_000
    property "deleting project removes tasks, bom items, and journal entries" do
      check all(
              project_name <- project_name_gen(),
              task_titles <- list_of(short_text_gen(), min_length: 1, max_length: 3),
              bom_names <- list_of(short_text_gen(), min_length: 1, max_length: 3),
              journal_bodies <- list_of(body_gen(), min_length: 1, max_length: 3),
              max_runs: @max_runs
            ) do
        project = create_project!(project_name)

        task_ids =
          Enum.map(task_titles, fn title ->
            t = create_task!(project.id, title)
            t.id
          end)

        bom_ids =
          Enum.map(bom_names, fn name ->
            b = create_bom_item!(project.id, name)
            b.id
          end)

        journal_ids =
          Enum.map(journal_bodies, fn body ->
            j = create_journal_entry!(project.id, body)
            j.id
          end)

        {:ok, _} = Projects.delete_project(project)

        Enum.each(task_ids, fn id ->
          assert_raise Ecto.NoResultsError, fn -> Projects.get_task!(id) end
        end)

        Enum.each(bom_ids, fn id ->
          assert_raise Ecto.NoResultsError, fn -> Projects.get_bom_item!(id) end
        end)

        Enum.each(journal_ids, fn id ->
          assert_raise Ecto.NoResultsError, fn -> Projects.get_journal_entry!(id) end
        end)
      end
    end
  end

  describe "count_by_status across project lifecycle" do
    @tag timeout: 60_000
    property "counts track status transitions across multiple projects" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 4),
              target_status <- status_gen(),
              max_runs: @max_runs
            ) do
        counts_before = Projects.count_by_status()

        projects =
          Enum.map(names, fn name ->
            {:ok, p} = Projects.create_project(%{"name" => name})
            p
          end)

        all_updated =
          Enum.map(projects, fn p ->
            {:ok, updated} =
              Projects.update_project(p, %{"status" => to_string(target_status)})

            updated
          end)

        counts_after = Projects.count_by_status()

        assert Map.get(counts_after, target_status, 0) >=
                 Map.get(counts_before, target_status, 0) + length(names)

        Enum.each(all_updated, fn p -> Projects.delete_project(p) end)
      end
    end
  end

  describe "multi-resource project snapshot" do
    @tag timeout: 120_000
    property "project with tasks, bom, journal reflects all sub-resources" do
      check all(
              project_name <- project_name_gen(),
              task_title <- short_text_gen(),
              bom_name <- short_text_gen(),
              journal_body <- body_gen(),
              status <- task_status_gen(),
              priority <- priority_gen(),
              max_runs: @max_runs
            ) do
        {:ok, project} =
          Projects.create_project(%{"name" => project_name, "status" => "active"})

        {:ok, task} =
          Projects.create_task(%{
            "title" => task_title,
            "project_id" => project.id,
            "status" => to_string(status),
            "priority" => to_string(priority)
          })

        {:ok, bom} =
          Projects.create_bom_item(%{"name" => bom_name, "project_id" => project.id})

        {:ok, journal} =
          Projects.create_journal_entry(%{"body" => journal_body, "project_id" => project.id})

        assert Enum.any?(Projects.list_tasks(project.id), &(&1.id == task.id))
        assert Enum.any?(Projects.list_bom_items(project.id), &(&1.id == bom.id))
        assert Enum.any?(Projects.list_journal_entries(project.id), &(&1.id == journal.id))

        {:ok, updated_project} =
          Projects.update_project(project, %{"status" => "paused"})

        assert updated_project.status == :paused

        task_stats = Projects.task_stats(project.id)
        assert Map.get(task_stats, status, 0) >= 1
      end
    end
  end
end
