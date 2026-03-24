defmodule Forge.Projects.ProjectTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.Project

  @statuses [:idea, :active, :paused, :done]
  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]

  defp name_generator do
    string(:printable, min_length: 1, max_length: 100)
  end

  defp valid_url_generator do
    one_of([
      map(string(:alphanumeric, min_length: 1, max_length: 20), fn s -> "http://#{s}.test" end),
      map(string(:alphanumeric, min_length: 1, max_length: 20), fn s -> "https://#{s}.test" end)
    ])
  end

  defp changeset(attrs) do
    Ash.Changeset.for_create(Project, :create, attrs)
  end

  describe "for_create/3 with valid data" do
    property "accepts any non-empty name up to 100 chars" do
      check all(
              name <- name_generator(),
              status <- one_of(Enum.map(@statuses, &constant/1)),
              color <- one_of(Enum.map(@colors, &constant/1))
            ) do
        cs = changeset(%{name: name, status: status, color: color})
        assert cs.valid?
      end
    end

    property "accepts all valid status values" do
      check all(
              status <- one_of(Enum.map(@statuses, &constant/1)),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, status: status})
        assert cs.valid?
      end
    end

    property "accepts all valid color values" do
      check all(
              color <- one_of(Enum.map(@colors, &constant/1)),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, color: color})
        assert cs.valid?
      end
    end

    property "accepts valid http/https URLs" do
      check all(
              url <- valid_url_generator(),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, url: url})
        assert cs.valid?
      end
    end

    property "accepts nil URL (optional field)" do
      check all(name <- name_generator()) do
        cs = changeset(%{name: name})
        assert cs.valid?
      end
    end
  end

  describe "for_create/3 with invalid data" do
    property "rejects missing name" do
      check all(status <- one_of(Enum.map(@statuses, &constant/1))) do
        cs = changeset(%{status: status})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :name end)
      end
    end

    property "rejects nil name" do
      check all(status <- one_of(Enum.map(@statuses, &constant/1))) do
        cs = changeset(%{name: nil, status: status})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :name end)
      end
    end

    property "rejects names longer than 100 graphemes" do
      check all(
              extra <- string(:ascii, min_length: 1, max_length: 100),
              base = String.duplicate("a", 100)
            ) do
        name = base <> extra
        assert String.length(name) > 100
        cs = changeset(%{name: name})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :name end)
      end
    end

    property "rejects URLs not starting with http:// or https://" do
      bad_prefixes = ["ftp://", "//", "www.", ""]

      check all(
              prefix <- one_of(Enum.map(bad_prefixes, &constant/1)),
              suffix <- string(:alphanumeric, min_length: 1, max_length: 20),
              name <- name_generator()
            ) do
        bad_url = prefix <> suffix
        cs = changeset(%{name: name, url: bad_url})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :url end)
      end
    end
  end

  describe "statuses/0 and colors/0" do
    test "returns all expected statuses" do
      assert Project.statuses() == @statuses
    end

    test "returns all expected colors" do
      assert Project.colors() == @colors
    end
  end
end
