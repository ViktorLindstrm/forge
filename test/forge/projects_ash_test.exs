defmodule Forge.ProjectsAshTest do
  @moduledoc """
  Property-based tests for new Ash calculations, aggregates, and named actions.
  """
  use Forge.DataCase, async: true
  @moduletag :ash
  use ExUnitProperties

  require Ash.Query

  alias Forge.Projects
  alias Forge.Projects.{Project, Task, BomItem}

  @max_runs 15

  defp project_name_gen, do: string(:alphanumeric, min_length: 1, max_length: 80)
  defp short_text_gen, do: string(:alphanumeric, min_length: 1, max_length: 80)
  defp body_gen, do: string(:printable, min_length: 1, max_length: 200)

  defp status_gen do
    one_of(Enum.map(Project.statuses(), &constant/1))
  end

  defp create_project!(name, status \\ :idea) do
    {:ok, p} = Projects.create_project(%{"name" => name, "status" => to_string(status)})
    p
  end

  defp create_task!(project_id, title, attrs \\ %{}) do
    {:ok, t} =
      Projects.create_task(Map.merge(%{"title" => title, "project_id" => project_id}, attrs))

    t
  end

  defp create_bom_item!(project_id, name, attrs \\ %{}) do
    {:ok, b} =
      Projects.create_bom_item(Map.merge(%{"name" => name, "project_id" => project_id}, attrs))

    b
  end

  # ── Named read actions ────────────────────────────────────────────────────

  describe "Task :by_project named action" do
    @describetag :tasks
    @tag timeout: 60_000
    property "returns only tasks for the requested project" do
      check all(
              name <- project_name_gen(),
              title <- short_text_gen(),
              max_runs: @max_runs
            ) do
        p1 = create_project!(name)
        p2 = create_project!(name <> "_other")

        create_task!(p1.id, title)

        p2_tasks =
          Task
          |> Ash.Query.for_read(:by_project, %{project_id: p2.id})
          |> Ash.read!()

        assert Enum.all?(p2_tasks, &(&1.project_id == p2.id))
      end
    end

    @tag timeout: 60_000
    property "tasks returned are sorted: pinned first, then sort_order" do
      check all(
              name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 3, max_length: 5),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        tasks = Enum.map(titles, &create_task!(project.id, &1))

        [t1, t2 | _] = tasks
        {:ok, _} = Projects.pin_task(t1.id, :current)
        {:ok, _} = Projects.pin_task(t2.id, :upcoming)

        sorted =
          Task
          |> Ash.Query.for_read(:by_project, %{project_id: project.id})
          |> Ash.read!()

        assert hd(sorted).pin_status == :current
        assert Enum.at(sorted, 1).pin_status == :upcoming
      end
    end
  end

  describe "BomItem :by_project named action" do
    @describetag :bom
    @tag timeout: 60_000
    property "returns only bom items for the requested project" do
      check all(
              name <- project_name_gen(),
              item_name <- short_text_gen(),
              max_runs: @max_runs
            ) do
        p1 = create_project!(name)
        p2 = create_project!(name <> "_bom_other")

        create_bom_item!(p1.id, item_name)

        p2_items =
          BomItem
          |> Ash.Query.for_read(:by_project, %{project_id: p2.id})
          |> Ash.read!()

        assert Enum.all?(p2_items, &(&1.project_id == p2.id))
      end
    end
  end

  # ── Task.overdue? calculation ─────────────────────────────────────────────

  describe "Task.overdue? calculation" do
    @describetag :tasks
    @tag timeout: 60_000
    property "overdue? is true for past due dates on non-done tasks" do
      check all(
              name <- project_name_gen(),
              title <- short_text_gen(),
              days_past <- integer(1..30),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        past_date = Date.add(Date.utc_today(), -days_past)

        task = create_task!(project.id, title, %{"due_date" => past_date})

        [loaded] =
          Task
          |> Ash.Query.filter(id == ^task.id)
          |> Ash.Query.load([:overdue?])
          |> Ash.read!()

        assert loaded.overdue? == true
      end
    end

    @tag timeout: 60_000
    property "overdue? is false for future due dates" do
      check all(
              name <- project_name_gen(),
              title <- short_text_gen(),
              days_future <- integer(1..30),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        future_date = Date.add(Date.utc_today(), days_future)

        task = create_task!(project.id, title, %{"due_date" => future_date})

        [loaded] =
          Task
          |> Ash.Query.filter(id == ^task.id)
          |> Ash.Query.load([:overdue?])
          |> Ash.read!()

        assert loaded.overdue? == false
      end
    end

    @tag timeout: 60_000
    property "overdue? is false when task is done even with past due date" do
      check all(
              name <- project_name_gen(),
              title <- short_text_gen(),
              days_past <- integer(1..30),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        past_date = Date.add(Date.utc_today(), -days_past)

        task = create_task!(project.id, title, %{"due_date" => past_date})
        {:ok, done_task} = Projects.toggle_task_done(task)
        assert done_task.status == :done

        [loaded] =
          Task
          |> Ash.Query.filter(id == ^done_task.id)
          |> Ash.Query.load([:overdue?])
          |> Ash.read!()

        assert loaded.overdue? == false
      end
    end

    @tag timeout: 60_000
    property "overdue? is false when no due_date set" do
      check all(
              name <- project_name_gen(),
              title <- short_text_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        task = create_task!(project.id, title)

        [loaded] =
          Task
          |> Ash.Query.filter(id == ^task.id)
          |> Ash.Query.load([:overdue?])
          |> Ash.read!()

        assert loaded.overdue? == false
      end
    end
  end

  # ── Task done_subtask_count aggregate ────────────────────────────────────

  describe "Task done_subtask_count aggregate" do
    @describetag :tasks
    @tag timeout: 60_000
    property "done_subtask_count reflects completed subtasks" do
      check all(
              name <- project_name_gen(),
              parent_title <- short_text_gen(),
              sub_titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(name)

        {:ok, parent} =
          Projects.create_task(%{"title" => parent_title, "project_id" => project.id})

        subtasks =
          Enum.map(sub_titles, fn title ->
            create_task!(project.id, title, %{"parent_task_id" => parent.id})
          end)

        to_complete = Enum.take(subtasks, 1)

        Enum.each(to_complete, fn sub ->
          {:ok, _} = Projects.toggle_task_done(sub)
        end)

        [loaded_parent] =
          Task
          |> Ash.Query.filter(id == ^parent.id)
          |> Ash.Query.load([:done_subtask_count, :subtask_count])
          |> Ash.read!()

        assert loaded_parent.done_subtask_count == length(to_complete)
        assert loaded_parent.subtask_count == length(sub_titles)
      end
    end
  end

  # ── Project.completion_percentage calculation ─────────────────────────────

  describe "Project.completion_percentage calculation" do
    @describetag :projects
    @tag timeout: 60_000
    property "completion_percentage is nil when no tasks" do
      check all(
              name <- project_name_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(name)

        [loaded] =
          Project
          |> Ash.Query.filter(id == ^project.id)
          |> Ash.Query.load([:completion_percentage])
          |> Ash.read!()

        assert loaded.completion_percentage == nil
      end
    end

    @tag timeout: 60_000
    property "completion_percentage reflects the ratio of done tasks" do
      check all(
              name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 2, max_length: 6),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        tasks = Enum.map(titles, &create_task!(project.id, &1))

        done_count = div(length(tasks), 2)
        to_complete = Enum.take(tasks, done_count)
        Enum.each(to_complete, fn t -> Projects.toggle_task_done(t) end)

        [loaded] =
          Project
          |> Ash.Query.filter(id == ^project.id)
          |> Ash.Query.load([:completion_percentage, :task_count, :done_task_count])
          |> Ash.read!()

        expected =
          if loaded.task_count == 0,
            do: nil,
            else: loaded.done_task_count / loaded.task_count * 100.0

        assert_in_delta loaded.completion_percentage, expected, 0.001
      end
    end
  end

  # ── Project.received_bom_item_count aggregate ─────────────────────────────

  describe "Project.received_bom_item_count aggregate" do
    @describetag :projects
    @tag timeout: 60_000
    property "received_bom_item_count matches items with :received status" do
      check all(
              name <- project_name_gen(),
              item_names <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        items = Enum.map(item_names, &create_bom_item!(project.id, &1))

        to_receive = Enum.take(items, 1)
        Enum.each(to_receive, fn item -> Projects.update_bom_item(item, %{status: :received}) end)

        [loaded] =
          Project
          |> Ash.Query.filter(id == ^project.id)
          |> Ash.Query.load([:received_bom_item_count, :bom_item_count])
          |> Ash.read!()

        assert loaded.received_bom_item_count == length(to_receive)
        assert loaded.bom_item_count == length(item_names)
      end
    end
  end

  # ── BomItem :toggle_status action ─────────────────────────────────────────

  describe "BomItem :toggle_status action" do
    @describetag :bom
    @tag timeout: 60_000
    property "status cycles: needed → ordered → received → needed" do
      check all(
              name <- project_name_gen(),
              item_name <- short_text_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        item = create_bom_item!(project.id, item_name)

        assert item.status == :needed

        {:ok, after_first} = Projects.toggle_bom_item_status(item)
        assert after_first.status == :ordered

        {:ok, after_second} = Projects.toggle_bom_item_status(after_first)
        assert after_second.status == :received

        {:ok, after_third} = Projects.toggle_bom_item_status(after_second)
        assert after_third.status == :needed
      end
    end

    @tag timeout: 60_000
    property "toggle_status on :ordered item produces :received" do
      check all(
              name <- project_name_gen(),
              item_name <- short_text_gen(),
              max_runs: @max_runs
            ) do
        project = create_project!(name)

        {:ok, item} =
          Projects.create_bom_item(%{
            "name" => item_name,
            "project_id" => project.id,
            "status" => "ordered"
          })

        {:ok, toggled} = Projects.toggle_bom_item_status(item)
        assert toggled.status == :received
      end
    end
  end

  # ── count_by_status using Ash.count! ─────────────────────────────────────

  describe "count_by_status" do
    @describetag :projects
    @tag timeout: 60_000
    property "returns correct counts for each status" do
      check all(
              status <- status_gen(),
              names <- list_of(project_name_gen(), min_length: 1, max_length: 3),
              max_runs: @max_runs
            ) do
        counts_before = Projects.count_by_status()
        before_count = Map.get(counts_before, status, 0)

        projects =
          Enum.map(names, fn name ->
            {:ok, p} = Projects.create_project(%{"name" => name, "status" => to_string(status)})
            p
          end)

        counts_after = Projects.count_by_status()
        assert Map.get(counts_after, status, 0) == before_count + length(names)

        Enum.each(projects, fn p -> Projects.delete_project(p) end)
      end
    end
  end

  # ── task_stats using Ash.count! ───────────────────────────────────────────

  describe "task_stats" do
    @describetag :tasks
    @tag timeout: 60_000
    property "task_stats returns per-status counts for the project only" do
      check all(
              name <- project_name_gen(),
              titles <- list_of(short_text_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        project = create_project!(name)
        other_project = create_project!(name <> "_other")

        tasks = Enum.map(titles, &create_task!(project.id, &1))
        create_task!(other_project.id, "unrelated")

        [to_toggle | _rest] = tasks
        {:ok, _} = Projects.toggle_task_done(to_toggle)

        stats = Projects.task_stats(project.id)

        assert Map.get(stats, :done, 0) >= 1
        assert Map.get(stats, :todo, 0) == length(tasks) - 1

        total_from_stats = stats |> Map.values() |> Enum.sum()
        assert total_from_stats == length(tasks)
      end
    end
  end

  # ── list_tasks_with_subtasks using relationship load ─────────────────────

  describe "list_tasks_with_subtasks" do
    @describetag :tasks
    @tag timeout: 60_000
    property "returns flat list: parent followed immediately by its subtasks" do
      check all(
              name <- project_name_gen(),
              parent_title <- short_text_gen(),
              sub_titles <- list_of(short_text_gen(), min_length: 2, max_length: 3),
              max_runs: @max_runs
            ) do
        project = create_project!(name)

        {:ok, parent} =
          Projects.create_task(%{"title" => parent_title, "project_id" => project.id})

        sub_ids =
          Enum.map(sub_titles, fn title ->
            {:ok, sub} =
              Projects.create_task(%{
                "title" => title,
                "project_id" => project.id,
                "parent_task_id" => parent.id
              })

            sub.id
          end)

        flat = Projects.list_tasks_with_subtasks(project.id)

        parent_index = Enum.find_index(flat, &(&1.id == parent.id))
        assert parent_index != nil

        sub_indices =
          Enum.map(sub_ids, fn id -> Enum.find_index(flat, &(&1.id == id)) end)

        assert Enum.all?(sub_indices, fn idx -> idx != nil and idx > parent_index end)
      end
    end
  end

  # ── journal_entries :by_project with pagination ───────────────────────────

  describe "JournalEntry :by_project pagination" do
    @describetag :journal
    @tag timeout: 60_000
    property "page and per_page arguments scope results correctly" do
      check all(
              name <- project_name_gen(),
              bodies <- list_of(body_gen(), min_length: 4, max_length: 6),
              max_runs: @max_runs
            ) do
        project = create_project!(name)

        Enum.each(bodies, fn body ->
          {:ok, _} =
            Projects.create_journal_entry(%{"body" => body, "project_id" => project.id})
        end)

        %{entries: page1} = Projects.list_journal_entries_page(project.id, 1, 2)
        %{entries: page2} = Projects.list_journal_entries_page(project.id, 2, 2)

        assert length(page1) == 2
        assert length(page2) == 2

        p1_ids = MapSet.new(page1, & &1.id)
        p2_ids = MapSet.new(page2, & &1.id)
        assert MapSet.disjoint?(p1_ids, p2_ids)
      end
    end
  end
end
