defmodule Forge.Projects.TaskTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.Task

  @actions_with_atomic_upgrade [:update, :toggle_done, :pin, :unpin]

  @statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]

  defp title_generator do
    string(:printable, min_length: 1, max_length: 200)
  end

  defp changeset(attrs) do
    Ash.Changeset.for_create(Task, :create, attrs)
  end

  describe "for_create/3 with valid data" do
    property "accepts any non-empty title with project_id" do
      check all(
              title <- title_generator(),
              status <- one_of(Enum.map(@statuses, &constant/1)),
              priority <- one_of(Enum.map(@priorities, &constant/1))
            ) do
        cs = changeset(%{title: title, status: status, priority: priority, project_id: 999_999})
        assert cs.valid?
      end
    end

    property "accepts all valid status values" do
      check all(
              status <- one_of(Enum.map(@statuses, &constant/1)),
              title <- title_generator()
            ) do
        cs = changeset(%{title: title, project_id: 1, status: status})
        assert cs.valid?
      end
    end

    property "accepts all valid priority values" do
      check all(
              priority <- one_of(Enum.map(@priorities, &constant/1)),
              title <- title_generator()
            ) do
        cs = changeset(%{title: title, project_id: 1, priority: priority})
        assert cs.valid?
      end
    end

    property "accepts optional due_date as Date" do
      check all(
              year <- integer(2000..2099),
              month <- integer(1..12),
              day <- integer(1..28),
              title <- title_generator()
            ) do
        due = Date.new!(year, month, day)
        cs = changeset(%{title: title, project_id: 1, due_date: due})
        assert cs.valid?
      end
    end

    property "accepts positive integer sort_order" do
      check all(
              sort_order <- positive_integer(),
              title <- title_generator()
            ) do
        cs = changeset(%{title: title, project_id: 1, sort_order: sort_order})
        assert cs.valid?
      end
    end
  end

  describe "for_create/3 with invalid data" do
    property "rejects missing title" do
      check all(status <- one_of(Enum.map(@statuses, &constant/1))) do
        cs = changeset(%{status: status, project_id: 1})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :title end)
      end
    end

    property "rejects nil title" do
      check all(status <- one_of(Enum.map(@statuses, &constant/1))) do
        cs = changeset(%{title: nil, status: status, project_id: 1})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :title end)
      end
    end

    property "rejects missing project_id" do
      check all(title <- title_generator()) do
        cs = changeset(%{title: title})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :project_id end)
      end
    end
  end

  describe "statuses/0 and priorities/0" do
    test "returns all expected statuses" do
      assert Task.statuses() == @statuses
    end

    test "returns all expected priorities" do
      assert Task.priorities() == @priorities
    end
  end

  describe "atomic upgrade configuration" do
    property "enables atomic_upgrade? for key update actions" do
      check all(action <- member_of(@actions_with_atomic_upgrade)) do
        assert %{atomic_upgrade?: true} =
                 Task
                 |> Ash.Resource.Info.action(action)
                 |> Map.take([:atomic_upgrade?])
      end
    end
  end
end
