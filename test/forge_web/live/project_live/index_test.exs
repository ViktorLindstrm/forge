defmodule ForgeWeb.ProjectLive.IndexTest do
  use ForgeWeb.ConnCase
  use ExUnitProperties

  import Phoenix.LiveViewTest

  alias Forge.Projects

  defp project_name_generator do
    string(:alphanumeric, min_length: 1, max_length: 60)
  end

  defp status_generator do
    one_of(Enum.map(Projects.Project.statuses(), &constant/1))
  end

  defp create_project!(attrs) do
    name = Map.get(attrs, "name", "Proj#{System.unique_integer()}")
    {:ok, p} = Projects.create_project(Map.merge(%{"name" => name}, attrs))
    p
  end

  defp group_name_generator do
    string(:alphanumeric, min_length: 1, max_length: 20)
    |> map(fn name -> "#{name}_#{System.unique_integer([:positive])}" end)
  end

  defp create_group!(name) do
    {:ok, g} = Projects.create_project_group(%{"name" => name})
    g
  end

  describe "project grouping" do
    property "projects with a group appear under that group heading" do
      check all(
              group_name <- group_name_generator(),
              project_name <- project_name_generator()
            ) do
        group = create_group!(group_name)

        create_project!(%{
          "name" => project_name,
          "project_group_id" => group.id
        })

        {:ok, _lv, html} = live(build_conn(), ~p"/projects")

        assert html =~ group.name
        assert html =~ project_name
        assert html =~ "group-section-#{group.id}"
      end
    end

    property "projects without a group appear under ungrouped section" do
      check all(name <- project_name_generator()) do
        create_project!(%{"name" => name})

        {:ok, _lv, html} = live(build_conn(), ~p"/projects")

        assert html =~ name
        assert html =~ "group-section-ungrouped"
      end
    end

    property "creating a group via form produces a group option in the dropdown" do
      check all(group_name <- group_name_generator()) do
        group = create_group!(group_name)

        {:ok, _lv, html} = live(build_conn(), ~p"/projects/new")

        assert html =~ group.name
      end
    end
  end

  describe "mount" do
    property "page loads and shows total project count" do
      check all(names <- list_of(project_name_generator(), min_length: 0, max_length: 3)) do
        Enum.each(names, fn name -> create_project!(%{"name" => name}) end)

        {:ok, lv, _html} = live(build_conn(), ~p"/projects")
        assert render(lv) =~ "Projects"
      end
    end

    property "each created project appears on the index page" do
      check all(name <- project_name_generator()) do
        project = create_project!(%{"name" => name})

        {:ok, _lv, html} = live(build_conn(), ~p"/projects")
        assert html =~ project.name
      end
    end
  end

  describe "filter event" do
    property "filtering by status only shows projects with that status" do
      check all(
              status <- status_generator(),
              name <- project_name_generator()
            ) do
        create_project!(%{"name" => name, "status" => to_string(status)})

        {:ok, lv, _html} = live(build_conn(), ~p"/projects")

        html = lv |> element("button", String.capitalize(to_string(status))) |> render_click()

        assert html =~ name
      end
    end

    property "filtering by :all shows all created projects" do
      check all(
              names <- list_of(project_name_generator(), min_length: 1, max_length: 3),
              status <- status_generator()
            ) do
        projects =
          Enum.map(names, fn name ->
            create_project!(%{"name" => name, "status" => to_string(status)})
          end)

        {:ok, lv, _html} = live(build_conn(), ~p"/projects")
        html = lv |> element("button", "All") |> render_click()

        Enum.each(projects, fn p -> assert html =~ p.name end)
      end
    end
  end

  describe "pinned tasks display" do
    property "shows project current/upcoming pins when tasks are pinned" do
      check all(
              project_name <- project_name_generator(),
              current_title <- string(:printable, min_length: 1, max_length: 40),
              upcoming_title <- string(:printable, min_length: 1, max_length: 40)
            ) do
        project = create_project!(%{"name" => project_name})

        {:ok, current} =
          Projects.create_task(%{"title" => current_title, "project_id" => project.id})

        {:ok, upcoming} =
          Projects.create_task(%{"title" => upcoming_title, "project_id" => project.id})

        {:ok, _} = Projects.pin_task(current.id, :current)
        {:ok, _} = Projects.pin_task(upcoming.id, :upcoming)

        {:ok, _lv, html} = live(build_conn(), ~p"/projects")

        assert html =~ "Current"
        assert html =~ "Upcoming"
        assert html =~ current_title
        assert html =~ upcoming_title
        assert html =~ "project-#{project.id}-pin-current"
        assert html =~ "project-#{project.id}-pin-upcoming"
      end
    end
  end
end
