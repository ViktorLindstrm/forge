defmodule ForgeWeb.ProjectLive.ToggleTasksTest do
  use ForgeWeb.ConnCase
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  defp create_project!(attrs \\ %{}) do
    base = %{"name" => "P#{System.unique_integer()}"}

    # tasks_enabled is not accepted on create action. Create first, then update if provided.
    {create_attrs, update_tasks_enabled} =
      case Map.pop(attrs, "tasks_enabled") do
        {nil, _} -> {attrs, nil}
        {val, _} -> {Map.delete(attrs, "tasks_enabled"), val}
      end

    {:ok, p} = Projects.create_project(Map.merge(base, create_attrs))

    if update_tasks_enabled != nil do
      {:ok, p} = Projects.update_project(p, %{"tasks_enabled" => update_tasks_enabled})
      p
    else
      p
    end
  end

  describe "toggle tasks enabled from edit form" do
    property "clicking the switch toggles tasks_enabled in the database" do
      check all(initial <- boolean()) do
        project = create_project!(%{"tasks_enabled" => to_string(initial)})

        {:ok, lv, _html} = live(build_conn(), ~p"/projects/#{project.id}/edit?return_to=show")

        lv |> element("#toggle-tasks-enabled") |> render_click()

        reloaded = Projects.get_project!(project.id)
        assert reloaded.tasks_enabled == !initial
      end
    end
  end
end
