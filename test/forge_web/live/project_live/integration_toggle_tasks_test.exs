defmodule ForgeWeb.ProjectLive.IntegrationToggleTasksTest do
  use ForgeWeb.ConnCase
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  defp name_generator, do: string(:alphanumeric, min_length: 8, max_length: 40)

  defp create_project!(attrs \\ %{}) do
    base = %{"name" => "P#{System.unique_integer()}"}

    # Create project without tasks_enabled then update if provided
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

  defp create_task!(project, title) do
    {:ok, t} = Projects.create_task(%{"title" => title, "project_id" => project.id})
    t
  end

  describe "integration: toggling tasks via settings and save" do
    property "task visibility follows settings saved in edit form" do
      check all(title <- name_generator()) do
        # create project with tasks enabled and a task
        project = create_project!(%{"tasks_enabled" => true})
        task = create_task!(project, title)

        # Visit show page and ensure task is visible
        {:ok, _lv, show_html} = live(build_conn(), ~p"/projects/#{project.id}")
        assert show_html =~ title

        # Go to edit page, toggle tasks off via the switch, then click Save
        {:ok, lv_edit, _edit_html} =
          live(build_conn(), ~p"/projects/#{project.id}/edit?return_to=show")

        # click the toggle (this handler saves immediately); also submit the form to simulate user pressing Save
        lv_edit |> element("#toggle-tasks-enabled") |> render_click()

        # Submit the form (Save changes)
        lv_edit
        |> form("#project-form", form: %{})
        |> render_submit()

        # Reload show page and assert task is not visible
        {:ok, _lv2, html_after_disable} = live(build_conn(), ~p"/projects/#{project.id}")
        refute html_after_disable =~ title

        # Now re-enable via edit form
        {:ok, lv_edit2, _html2} =
          live(build_conn(), ~p"/projects/#{project.id}/edit?return_to=show")

        lv_edit2 |> element("#toggle-tasks-enabled") |> render_click()

        lv_edit2
        |> form("#project-form", form: %{})
        |> render_submit()

        # Reload show and verify task is visible again
        {:ok, _lv3, html_after_enable} = live(build_conn(), ~p"/projects/#{project.id}")
        assert html_after_enable =~ title
      end
    end
  end
end
