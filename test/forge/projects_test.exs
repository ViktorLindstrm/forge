defmodule Forge.ProjectsTest do
  use Forge.DataCase
  use ExUnitProperties

  alias Forge.Projects
  alias Forge.Projects.{Project}

  defp create_project!(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Map.merge(%{"name" => Map.get(attrs, "name", "Test Project")})
      |> Projects.create_project()

    project
  end

  defp project_name_generator do
    string(:alphanumeric, min_length: 1, max_length: 80)
  end

  defp title_generator do
    string(:printable, min_length: 1, max_length: 100)
  end

  defp status_generator do
    one_of(Enum.map(Project.statuses(), &constant/1))
  end

  describe "create_project/1" do
    property "creates a project for any valid name" do
      check all(name <- project_name_generator()) do
        assert {:ok, %Project{} = p} = Projects.create_project(%{"name" => name})
        assert p.name == name
        assert p.id != nil
      end
    end

    property "returns error for missing name" do
      check all(status <- status_generator()) do
        assert {:error, %Ash.Error.Invalid{}} =
                 Projects.create_project(%{"status" => to_string(status)})
      end
    end
  end

  describe "list_projects/0" do
    property "returns at least the projects that were created" do
      check all(names <- list_of(project_name_generator(), min_length: 1, max_length: 5)) do
        before_ids = Projects.list_projects() |> Enum.map(& &1.id) |> MapSet.new()

        created =
          Enum.map(names, fn name ->
            {:ok, p} = Projects.create_project(%{"name" => name})
            p.id
          end)

        after_list = Projects.list_projects() |> Enum.map(& &1.id) |> MapSet.new()
        assert Enum.all?(created, &MapSet.member?(after_list, &1))
        assert MapSet.subset?(before_ids, after_list)
      end
    end
  end

  describe "list_projects_by_status/1" do
    property "only returns projects with the requested status" do
      check all(
              status <- status_generator(),
              name <- project_name_generator()
            ) do
        {:ok, _p} =
          Projects.create_project(%{"name" => name, "status" => to_string(status)})

        results = Projects.list_projects_by_status(status)
        assert Enum.all?(results, fn p -> p.status == status end)
      end
    end
  end

  describe "get_project!/1" do
    property "retrieves the same project that was created" do
      check all(name <- project_name_generator()) do
        {:ok, created} = Projects.create_project(%{"name" => name})
        fetched = Projects.get_project!(created.id)
        assert fetched.id == created.id
        assert fetched.name == created.name
      end
    end
  end

  describe "update_project/2" do
    property "updates the project name" do
      check all(
              old_name <- project_name_generator(),
              new_name <- project_name_generator()
            ) do
        {:ok, project} = Projects.create_project(%{"name" => old_name})
        assert {:ok, updated} = Projects.update_project(project, %{"name" => new_name})
        assert updated.name == new_name
      end
    end

    property "returns error changeset when clearing name" do
      check all(name <- project_name_generator()) do
        {:ok, project} = Projects.create_project(%{"name" => name})
        assert {:error, %Ash.Error.Invalid{}} = Projects.update_project(project, %{"name" => nil})
      end
    end
  end

  defp payload_generator(ids) do
    gen all(ordered <- shuffle(ids)) do
      ordered
    end
  end

  describe "reorder_tasks/2" do
    @tag timeout: 120_000
    property "persists sort_order to match provided id order" do
      check all(titles <- list_of(title_generator(), min_length: 2, max_length: 5)) do
        project = create_project!()

        created =
          Enum.map(titles, fn title ->
            {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})
            task
          end)

        ids = Enum.map(created, & &1.id)

        check all(ordered_ids <- payload_generator(ids)) do
          :ok = Projects.reorder_tasks(project.id, ordered_ids)

          tasks = Projects.list_tasks(project.id)
          assert Enum.map(tasks, & &1.id) == ordered_ids

          orders = Enum.map(tasks, & &1.sort_order)
          assert orders == Enum.to_list(1..length(ordered_ids))
        end
      end
    end
  end

  describe "count_by_status/0" do
    property "returns a count of at least 1 for a status after creating a project with that status" do
      check all(
              status <- status_generator(),
              name <- project_name_generator()
            ) do
        {:ok, _} = Projects.create_project(%{"name" => name, "status" => to_string(status)})
        counts = Projects.count_by_status()
        assert Map.get(counts, status, 0) >= 1
      end
    end

    property "total count equals number of projects created" do
      check all(names <- list_of(project_name_generator(), min_length: 1, max_length: 5)) do
        before_total = Projects.count_by_status() |> Map.values() |> Enum.sum()

        Enum.each(names, fn name ->
          Projects.create_project(%{"name" => name})
        end)

        after_total = Projects.count_by_status() |> Map.values() |> Enum.sum()
        assert after_total == before_total + length(names)
      end
    end
  end

  describe "create_task/1 sort_order auto-assignment" do
    property "tasks get incrementing sort_order within a project" do
      check all(titles <- list_of(title_generator(), min_length: 2, max_length: 5)) do
        project = create_project!()

        tasks =
          Enum.map(titles, fn title ->
            {:ok, t} = Projects.create_task(%{"title" => title, "project_id" => project.id})
            t
          end)

        sort_orders = Enum.map(tasks, & &1.sort_order)
        assert sort_orders == Enum.sort(sort_orders)
        assert length(Enum.uniq(sort_orders)) == length(sort_orders)
      end
    end

    property "sort_order is independent between projects" do
      check all(title <- title_generator()) do
        p1 = create_project!()
        p2 = create_project!()

        {:ok, t1} = Projects.create_task(%{"title" => title, "project_id" => p1.id})
        {:ok, t2} = Projects.create_task(%{"title" => title, "project_id" => p2.id})

        assert t1.sort_order == t2.sort_order
      end
    end
  end

  describe "create_task/1 and list_tasks/1" do
    property "created tasks appear in list_tasks for the project" do
      check all(title <- title_generator()) do
        project = create_project!()

        assert {:ok, task} =
                 Projects.create_task(%{"title" => title, "project_id" => project.id})

        tasks = Projects.list_tasks(project.id)
        assert Enum.any?(tasks, fn t -> t.id == task.id end)
      end
    end

    property "list_tasks only returns tasks belonging to the given project" do
      check all(title <- title_generator()) do
        p1 = create_project!()
        p2 = create_project!()
        {:ok, _} = Projects.create_task(%{"title" => title, "project_id" => p1.id})

        p2_tasks = Projects.list_tasks(p2.id)
        assert Enum.all?(p2_tasks, fn t -> t.project_id == p2.id end)
      end
    end
  end

  describe "task pinning" do
    @tag timeout: 120_000
    property "only one current pin exists per project" do
      check all(titles <- list_of(title_generator(), min_length: 2, max_length: 5)) do
        project = create_project!()

        tasks =
          Enum.map(titles, fn title ->
            {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})
            task
          end)

        check all(
                t1 <- member_of(tasks),
                t2 <- member_of(tasks)
              ) do
          {:ok, _} = Projects.pin_task(t1.id, :current)
          {:ok, _} = Projects.pin_task(t2.id, :current)

          reloaded = Projects.list_tasks(project.id)
          assert reloaded |> Enum.count(&(&1.pin_status == :current)) == 1
          assert Enum.any?(reloaded, &(&1.id == t2.id and &1.pin_status == :current))
        end
      end
    end

    @tag timeout: 120_000
    property "only one upcoming pin exists per project" do
      check all(titles <- list_of(title_generator(), min_length: 2, max_length: 5)) do
        project = create_project!()

        tasks =
          Enum.map(titles, fn title ->
            {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})
            task
          end)

        check all(
                t1 <- member_of(tasks),
                t2 <- member_of(tasks)
              ) do
          {:ok, _} = Projects.pin_task(t1.id, :upcoming)
          {:ok, _} = Projects.pin_task(t2.id, :upcoming)

          reloaded = Projects.list_tasks(project.id)
          assert reloaded |> Enum.count(&(&1.pin_status == :upcoming)) == 1
          assert Enum.any?(reloaded, &(&1.id == t2.id and &1.pin_status == :upcoming))
        end
      end
    end

    property "pinning does not affect other projects" do
      check all(title1 <- title_generator(), title2 <- title_generator()) do
        p1 = create_project!()
        p2 = create_project!()

        {:ok, t1} = Projects.create_task(%{"title" => title1, "project_id" => p1.id})
        {:ok, t2} = Projects.create_task(%{"title" => title2, "project_id" => p2.id})

        {:ok, _} = Projects.pin_task(t1.id, :current)

        assert Projects.get_task!(t2.id).pin_status == nil
      end
    end

    property "toggling a pinned task to done clears its pin" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})

        {:ok, _} = Projects.pin_task(task.id, :current)
        pinned = Projects.get_task!(task.id)
        assert pinned.pin_status == :current

        {:ok, done_task} = Projects.toggle_task_done(pinned)
        assert done_task.status == :done
        assert done_task.pin_status == nil
      end
    end

    property "cannot pin a done task" do
      check all(title <- title_generator()) do
        project = create_project!()

        {:ok, task} =
          Projects.create_task(%{
            "title" => title,
            "project_id" => project.id,
            "status" => "done"
          })

        assert {:error, %Ash.Error.Invalid{}} = Projects.pin_task(task.id, :current)
      end
    end
  end
end
