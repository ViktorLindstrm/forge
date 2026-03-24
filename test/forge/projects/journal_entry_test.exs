defmodule Forge.Projects.JournalEntryTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.JournalEntry

  defp body_generator do
    string(:printable, min_length: 1, max_length: 500)
  end

  defp optional_title_generator do
    one_of([constant(nil), string(:printable, min_length: 1, max_length: 200)])
  end

  defp changeset(attrs) do
    Ash.Changeset.for_create(JournalEntry, :create, attrs)
  end

  describe "for_create/3 with valid data" do
    property "accepts any non-empty body with project_id" do
      check all(
              body <- body_generator(),
              title <- optional_title_generator()
            ) do
        base = %{body: body, project_id: 1}
        attrs = if title, do: Map.put(base, :title, title), else: base
        cs = changeset(attrs)
        assert cs.valid?
      end
    end

    property "accepts body without a title (title is optional)" do
      check all(body <- body_generator()) do
        cs = changeset(%{body: body, project_id: 1})
        assert cs.valid?
        refute Enum.any?(cs.errors, fn e -> e.field == :title end)
      end
    end

    property "accepts body with a title" do
      check all(
              body <- body_generator(),
              title <- string(:printable, min_length: 1, max_length: 200)
            ) do
        cs = changeset(%{body: body, title: title, project_id: 1})
        assert cs.valid?
      end
    end
  end

  describe "for_create/3 with invalid data" do
    property "rejects missing body" do
      check all(title <- optional_title_generator()) do
        base = %{project_id: 1}
        attrs = if title, do: Map.put(base, :title, title), else: base
        cs = changeset(attrs)
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :body end)
      end
    end

    property "rejects nil body" do
      check all(title <- optional_title_generator()) do
        base = %{body: nil, project_id: 1}
        attrs = if title, do: Map.put(base, :title, title), else: base
        cs = changeset(attrs)
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :body end)
      end
    end

    property "rejects empty string body (min length 1)" do
      check all(title <- optional_title_generator()) do
        base = %{body: "", project_id: 1}
        attrs = if title, do: Map.put(base, :title, title), else: base
        cs = changeset(attrs)
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :body end)
      end
    end

    property "rejects missing project_id" do
      check all(body <- body_generator()) do
        cs = changeset(%{body: body})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :project_id end)
      end
    end

    property "rejects nil project_id" do
      check all(body <- body_generator()) do
        cs = changeset(%{body: body, project_id: nil})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :project_id end)
      end
    end
  end
end
