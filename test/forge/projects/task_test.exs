defmodule Forge.Projects.TaskTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.Task

  @statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]

  defp title_generator do
    string(:printable, min_length: 1, max_length: 200)
  end

  defp valid_attrs_generator do
    gen all(
          title <- title_generator(),
          status <- one_of(Enum.map(@statuses, &constant/1)),
          priority <- one_of(Enum.map(@priorities, &constant/1))
        ) do
      %{
        "title" => title,
        "status" => to_string(status),
        "priority" => to_string(priority),
        "project_id" => 999_999
      }
    end
  end

  describe "changeset/2 with valid data" do
    property "accepts any non-empty title with project_id" do
      check all(attrs <- valid_attrs_generator()) do
        cs = Task.changeset(%Task{}, attrs)
        assert cs.valid?
      end
    end

    property "accepts all valid status values" do
      check all(
              status <- one_of(Enum.map(@statuses, &constant/1)),
              title <- title_generator()
            ) do
        cs =
          Task.changeset(%Task{}, %{
            "title" => title,
            "project_id" => 1,
            "status" => to_string(status)
          })

        assert cs.valid?
      end
    end

    property "accepts all valid priority values" do
      check all(
              priority <- one_of(Enum.map(@priorities, &constant/1)),
              title <- title_generator()
            ) do
        cs =
          Task.changeset(%Task{}, %{
            "title" => title,
            "project_id" => 1,
            "priority" => to_string(priority)
          })

        assert cs.valid?
      end
    end

    property "accepts optional due_date as ISO date string" do
      check all(
              year <- integer(2000..2099),
              month <- integer(1..12),
              day <- integer(1..28),
              title <- title_generator()
            ) do
        date_str =
          "#{year}-#{String.pad_leading(to_string(month), 2, "0")}-#{String.pad_leading(to_string(day), 2, "0")}"

        cs =
          Task.changeset(%Task{}, %{
            "title" => title,
            "project_id" => 1,
            "due_date" => date_str
          })

        assert cs.valid?
      end
    end

    property "accepts positive integer sort_order" do
      check all(
              sort_order <- positive_integer(),
              title <- title_generator()
            ) do
        cs =
          Task.changeset(%Task{}, %{
            "title" => title,
            "project_id" => 1,
            "sort_order" => sort_order
          })

        assert cs.valid?
      end
    end
  end

  describe "changeset/2 with invalid data" do
    property "rejects missing title" do
      check all(attrs <- valid_attrs_generator()) do
        cs = Task.changeset(%Task{}, Map.delete(attrs, "title"))
        refute cs.valid?
        assert :title in Keyword.keys(cs.errors)
      end
    end

    property "rejects nil title" do
      check all(attrs <- valid_attrs_generator()) do
        cs = Task.changeset(%Task{}, Map.put(attrs, "title", nil))
        refute cs.valid?
        assert :title in Keyword.keys(cs.errors)
      end
    end

    property "rejects missing project_id" do
      check all(title <- title_generator()) do
        cs = Task.changeset(%Task{}, %{"title" => title})
        refute cs.valid?
        assert :project_id in Keyword.keys(cs.errors)
      end
    end

    property "rejects nil project_id" do
      check all(title <- title_generator()) do
        cs = Task.changeset(%Task{}, %{"title" => title, "project_id" => nil})
        refute cs.valid?
        assert :project_id in Keyword.keys(cs.errors)
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
end
