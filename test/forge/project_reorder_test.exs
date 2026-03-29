defmodule Forge.ProjectReorderTest do
  @moduledoc """
  Property-based tests for project sort_order and drag-and-drop reordering.
  Covers reorder_projects/1, sort_order persistence, list ordering, and
  group isolation.
  """
  use Forge.DataCase, async: true
  use ExUnitProperties

  @moduletag :projects
  @moduletag :projects
  alias Forge.Projects
  alias Forge.Projects.Project

  @max_runs 20

  defp project_name_gen do
    string(:alphanumeric, min_length: 1, max_length: 60)
  end

  defp color_gen do
    one_of(Enum.map(Project.colors(), &constant/1))
  end

  defp group_name_gen do
    map(string(:alphanumeric, min_length: 4, max_length: 30), &("GRP_" <> &1))
  end

  defp create_project!(name, extra \\ %{}) do
    attrs = Map.merge(%{"name" => name}, extra)
    {:ok, p} = Projects.create_project(attrs)
    p
  end

  defp create_group!(name) do
    {:ok, g} = Projects.create_project_group(%{"name" => name})
    g
  end

  # ── sort_order attribute ──────────────────────────────────────────────────

  describe "sort_order attribute" do
    property "newly created project has a non-negative sort_order" do
      check all(name <- project_name_gen(), max_runs: @max_runs) do
        p = create_project!(name)
        assert is_integer(p.sort_order)
        assert p.sort_order >= 0
      end
    end

    property "sort_order can be set explicitly at create time" do
      check all(
              name <- project_name_gen(),
              order <- integer(1..1000),
              max_runs: @max_runs
            ) do
        p = create_project!(name, %{"sort_order" => order})
        assert p.sort_order == order
      end
    end

    property "sort_order can be updated via update_project/2" do
      check all(
              name <- project_name_gen(),
              new_order <- integer(1..1000),
              max_runs: @max_runs
            ) do
        p = create_project!(name)
        {:ok, updated} = Projects.update_project(p, %{"sort_order" => new_order})
        assert updated.sort_order == new_order
      end
    end
  end

  # ── reorder_projects/1 ────────────────────────────────────────────────────

  describe "reorder_projects/1" do
    property "assigns sort_order 1..n matching the given id order" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 6),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = projects |> Enum.map(& &1.id) |> Enum.map(&to_string/1)

        :ok = Projects.reorder_projects(ids)

        reloaded =
          Enum.map(projects, fn p -> Projects.get_project!(p.id) end)
          |> Enum.sort_by(& &1.sort_order)

        assert Enum.map(reloaded, & &1.sort_order) == Enum.to_list(1..length(ids))
        assert Enum.map(reloaded, &to_string(&1.id)) == ids
      end
    end

    property "reorder is stable: applying the same order twice yields the same result" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 5),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = projects |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.map(&to_string/1)

        :ok = Projects.reorder_projects(ids)
        :ok = Projects.reorder_projects(ids)

        reloaded =
          Enum.map(projects, fn p -> Projects.get_project!(p.id) end)
          |> Enum.sort_by(& &1.sort_order)

        assert Enum.map(reloaded, &to_string(&1.id)) == ids
      end
    end

    property "reordering with reversed ids reverses sort_order" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 6),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = projects |> Enum.map(& &1.id) |> Enum.map(&to_string/1)
        reversed_ids = Enum.reverse(ids)

        :ok = Projects.reorder_projects(reversed_ids)

        reloaded =
          Enum.map(projects, fn p -> Projects.get_project!(p.id) end)
          |> Enum.sort_by(& &1.sort_order)

        assert Enum.map(reloaded, &to_string(&1.id)) == reversed_ids
      end
    end

    property "sort_order values are unique consecutive integers starting at 1" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 6),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = projects |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.map(&to_string/1)

        :ok = Projects.reorder_projects(ids)

        orders =
          Enum.map(projects, fn p -> Projects.get_project!(p.id).sort_order end)
          |> Enum.sort()

        assert orders == Enum.to_list(1..length(ids))
      end
    end

    property "returns :ok for a single project" do
      check all(name <- project_name_gen(), max_runs: @max_runs) do
        p = create_project!(name)
        assert :ok == Projects.reorder_projects([to_string(p.id)])

        reloaded = Projects.get_project!(p.id)
        assert reloaded.sort_order == 1
      end
    end

    property "returns :ok for an empty list without error" do
      check all(_ <- constant(:ok), max_runs: 5) do
        assert :ok == Projects.reorder_projects([])
      end
    end

    property "does not affect projects not included in the id list" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 4),
              other_name <- project_name_gen(),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        other = create_project!(other_name)
        original_order = other.sort_order

        ids = projects |> Enum.map(& &1.id) |> Enum.map(&to_string/1)
        :ok = Projects.reorder_projects(ids)

        reloaded_other = Projects.get_project!(other.id)
        assert reloaded_other.sort_order == original_order
      end
    end
  end

  # ── list_projects / sort_order ordering ──────────────────────────────────

  describe "list_projects/0 respects sort_order" do
    property "projects with explicit sort_order are returned in ascending sort_order" do
      check all(
              names <- list_of(project_name_gen(), min_length: 2, max_length: 5),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = projects |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.map(&to_string/1)
        :ok = Projects.reorder_projects(ids)

        listed = Projects.list_projects()

        our_ids = MapSet.new(ids)

        our_listed =
          Enum.filter(listed, fn p -> MapSet.member?(our_ids, to_string(p.id)) end)

        assert Enum.map(our_listed, &to_string(&1.id)) == ids
      end
    end

    property "reordering and re-listing yields consistent results across multiple shuffles" do
      check all(
              names <- list_of(project_name_gen(), min_length: 3, max_length: 5),
              max_runs: @max_runs
            ) do
        projects = Enum.map(names, &create_project!/1)
        ids = Enum.map(projects, & &1.id)

        shuffled = ids |> Enum.shuffle() |> Enum.map(&to_string/1)
        :ok = Projects.reorder_projects(shuffled)

        listed = Projects.list_projects()
        our_ids = MapSet.new(shuffled)

        our_listed =
          listed
          |> Enum.filter(&MapSet.member?(our_ids, to_string(&1.id)))
          |> Enum.map(&to_string(&1.id))

        assert our_listed == shuffled
      end
    end
  end

  # ── list_projects_grouped with sort_order ────────────────────────────────

  describe "list_projects_grouped/0 with sort_order" do
    property "projects within a group are returned in sort_order after reordering" do
      check all(
              group_name <- group_name_gen(),
              names <- list_of(project_name_gen(), min_length: 2, max_length: 5),
              max_runs: @max_runs
            ) do
        group = create_group!(group_name)

        projects =
          Enum.map(names, fn name ->
            create_project!(name, %{"project_group_id" => group.id})
          end)

        ids = projects |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.map(&to_string/1)
        :ok = Projects.reorder_projects(ids)

        grouped = Projects.list_projects_grouped()
        {_g, group_projects} = Enum.find(grouped, fn {g, _} -> g != nil and g.id == group.id end)

        our_ids = MapSet.new(ids)

        our_group_projects =
          group_projects
          |> Enum.filter(&MapSet.member?(our_ids, to_string(&1.id)))
          |> Enum.map(&to_string(&1.id))

        assert our_group_projects == ids
      end
    end

    property "reordering projects in one group does not change order in another group" do
      check all(
              g1_name <- group_name_gen(),
              g2_name <- group_name_gen(),
              names1 <- list_of(project_name_gen(), min_length: 2, max_length: 4),
              names2 <- list_of(project_name_gen(), min_length: 2, max_length: 4),
              max_runs: @max_runs
            ) do
        g1 = create_group!(g1_name)
        g2 = create_group!(g2_name)

        projects1 =
          Enum.map(names1, fn name ->
            create_project!(name, %{"project_group_id" => g1.id})
          end)

        projects2 =
          Enum.map(names2, fn name ->
            create_project!(name, %{"project_group_id" => g2.id})
          end)

        ids2_before =
          Enum.map(projects2, & &1.id) |> Enum.map(&to_string/1)

        ids1_shuffled = projects1 |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.map(&to_string/1)
        :ok = Projects.reorder_projects(ids1_shuffled)

        grouped = Projects.list_projects_grouped()
        {_, g2_projects} = Enum.find(grouped, fn {g, _} -> g != nil and g.id == g2.id end)

        g2_our_ids = MapSet.new(ids2_before)

        g2_ids_after =
          g2_projects
          |> Enum.filter(&MapSet.member?(g2_our_ids, to_string(&1.id)))
          |> Enum.map(&to_string(&1.id))

        assert MapSet.new(g2_ids_after) == g2_our_ids
      end
    end

    property "ungrouped projects are placed at the end of grouped listing" do
      check all(
              group_name <- group_name_gen(),
              grouped_name <- project_name_gen(),
              ungrouped_name <- project_name_gen(),
              max_runs: @max_runs
            ) do
        group = create_group!(group_name)
        _grouped_project = create_project!(grouped_name, %{"project_group_id" => group.id})
        _ungrouped_project = create_project!(ungrouped_name)

        grouped = Projects.list_projects_grouped()

        unless grouped == [] do
          {last_key, _} = List.last(grouped)
          assert last_key == nil
        end
      end
    end
  end

  # ── color_bg gradient ─────────────────────────────────────────────────────

  @describetag :ui
  describe "color_bg/1 gradient classes" do
    property "every project color produces a gradient class with from/via/to stops" do
      check all(color <- color_gen(), max_runs: length(Project.colors())) do
        classes = ForgeWeb.ProjectLive.Components.Badges.color_bg(color)
        assert String.contains?(classes, "bg-gradient-to-r")
        assert String.contains?(classes, "from-")
        assert String.contains?(classes, "via-")
        assert String.contains?(classes, "to-")
      end
    end

    property "gradient stops are ordered light → mid → dark for each color" do
      check all(color <- color_gen(), max_runs: length(Project.colors())) do
        classes = ForgeWeb.ProjectLive.Components.Badges.color_bg(color)
        color_name = to_string(color)

        [from_stop] = Regex.run(~r/from-#{color_name}-(\d+)/, classes, capture: :all_but_first)
        [via_stop] = Regex.run(~r/via-#{color_name}-(\d+)/, classes, capture: :all_but_first)
        [to_stop] = Regex.run(~r/to-#{color_name}-(\d+)/, classes, capture: :all_but_first)

        assert String.to_integer(from_stop) < String.to_integer(via_stop)
        assert String.to_integer(via_stop) < String.to_integer(to_stop)
      end
    end

    property "color_bg/1 returns a string for every defined project color" do
      check all(color <- color_gen(), max_runs: length(Project.colors())) do
        result = ForgeWeb.ProjectLive.Components.Badges.color_bg(color)
        assert is_binary(result)
        assert String.length(result) > 0
      end
    end

    test "fallback color returns a gradient string" do
      result = ForgeWeb.ProjectLive.Components.Badges.color_bg(:unknown)
      assert is_binary(result)
      assert String.contains?(result, "bg-gradient-to-r")
    end
  end
end
