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

  describe "task_form/0" do
    test "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :create" do
      form = Tasks.task_form()
      assert %Phoenix.HTML.Form{} = form
      assert %AshPhoenix.Form{} = form.source
      assert form.source.resource == Forge.Projects.Task
      assert form.source.action == :create
      assert form.name == "task"
    end
  end

  describe "task_edit_form/1" do
    property "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :update" do
      check all(title <- title_generator()) do
        project = create_project!()
        {:ok, task} = Projects.create_task(%{"title" => title, "project_id" => project.id})

        form = Tasks.task_edit_form(task)
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.Task
        assert form.source.action == :update
        assert form.name == "task"
      end
    end
  end
end
