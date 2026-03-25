defmodule ForgeWeb.ProjectLive.TasksTest do
  use Forge.DataCase
  use ExUnitProperties

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Tasks

  defp create_project! do
    {:ok, p} = Projects.create_project(%{"name" => "Test #{System.unique_integer()}"})
    p
  end

  defp title_generator, do: string(:printable, min_length: 1, max_length: 100)

  defp whitespace_generator do
    one_of([constant(""), constant("   "), constant("\t"), constant("\n")])
  end

  describe "handle_task_create/2" do
    property "creates a task and returns stream reset with valid title" do
      check all(title <- title_generator()) do
        project = create_project!()
        params = %{"task" => %{"title" => title}}

        assert {:ok, result} = Tasks.handle_task_create(params, project.id)
        assert is_list(result.assigns)
        assert Keyword.has_key?(result.assigns, :task_counts)
        assert Keyword.has_key?(result.assigns, :task_form)
        assert Keyword.has_key?(result.assigns, :tasks_empty?)
        assert result.stream == {:reset, :tasks, Projects.list_tasks_with_subtasks(project.id)}
      end
    end

    property "returns :blank_title error for whitespace-only titles" do
      check all(ws <- whitespace_generator()) do
        project = create_project!()
        params = %{"task" => %{"title" => ws}}

        assert {:error, :blank_title} = Tasks.handle_task_create(params, project.id)
      end
    end

    property "tasks_empty? is false after first task creation" do
      check all(title <- title_generator()) do
        project = create_project!()
        params = %{"task" => %{"title" => title}}

        {:ok, result} = Tasks.handle_task_create(params, project.id)
        assert Keyword.get(result.assigns, :tasks_empty?) == false
      end
    end

    property "task_form is reset to empty after creation" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, result} = Tasks.handle_task_create(%{"task" => %{"title" => title}}, project.id)
        form = Keyword.get(result.assigns, :task_form)
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.Task
      end
    end
  end

  describe "handle_task_toggle/2" do
    property "toggles a todo task to done" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})
        assert task.status == :todo

        assert {:ok, result} = Tasks.handle_task_toggle(%{"id" => task.id}, project.id)
        assert is_list(result.assigns)
        assert Keyword.has_key?(result.assigns, :task_counts)

        toggled = Projects.get_task!(task.id)
        assert toggled.status == :done
      end
    end

    property "toggles a done task back to todo" do
      check all(title <- title_generator()) do
        project = create_project!()

        {:ok, task} =
          Projects.create_task(%{
            "title" => title,
            "project_id" => project.id,
            "status" => "done"
          })

        assert task.status == :done

        assert {:ok, _result} = Tasks.handle_task_toggle(%{"id" => task.id}, project.id)

        toggled = Projects.get_task!(task.id)
        assert toggled.status == :todo
      end
    end

    property "toggle result stream resets tasks list" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})

        {:ok, result} = Tasks.handle_task_toggle(%{"id" => task.id}, project.id)
        assert {:reset, :tasks, tasks} = result.stream
        assert is_list(tasks)
        assert Enum.any?(tasks, fn t -> t.id == task.id end)
      end
    end
  end

  describe "handle_task_update/2" do
    property "updates an existing task with valid title" do
      check all(title <- title_generator(), new_title <- title_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})

        params = %{
          "task_id" => task.id,
          "task" => %{
            "title" => new_title,
            "priority" => "high",
            "status" => "in_progress",
            "description" => "updated"
          }
        }

        assert {:ok, result} = Tasks.handle_task_update(params, project.id)
        assert {:reset, :tasks, _tasks} = result.stream

        updated = Projects.get_task!(task.id)
        assert updated.title == String.trim(new_title)
        assert updated.priority == :high
        assert updated.status == :in_progress
        assert updated.description == "updated"
      end
    end

    property "returns :blank_title for whitespace-only title" do
      check all(title <- title_generator(), ws <- whitespace_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})

        params = %{"task_id" => task.id, "task" => %{"title" => ws}}

        assert {:error, :blank_title} = Tasks.handle_task_update(params, project.id)
      end
    end
  end
end
