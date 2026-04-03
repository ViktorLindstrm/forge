defmodule Forge.Projects.JournalEntryTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.JournalEntry

  defp body_generator do
    string(:printable, min_length: 1, max_length: 500)
  end

  defp changeset(attrs) do
    Ash.Changeset.for_create(JournalEntry, :create, attrs)
  end

  describe "create with valid data" do
    property "accepts any non-empty body with project_id" do
      check all(body <- body_generator()) do
        cs = changeset(%{body: body, project_id: 1})
        assert cs.valid?
      end
    end

    property "accepts multi-line bodies" do
      check all(
              a <- string(:printable, min_length: 1, max_length: 100),
              b <- string(:printable, min_length: 1, max_length: 100)
            ) do
        cs = changeset(%{body: a <> "\n" <> b, project_id: 1})
        assert cs.valid?
      end
    end
  end

  describe "create with invalid data" do
    property "title attribute is not accepted in create action" do
      check all(body <- body_generator()) do
        cs = changeset(%{body: body, title: "some title", project_id: 1})
        refute cs.valid?

        assert Enum.any?(cs.errors, fn e ->
                 match?(%Ash.Error.Invalid.NoSuchInput{input: :title}, e)
               end)
      end
    end

    property "rejects missing body" do
      check all(_ <- constant(:ok)) do
        cs = changeset(%{project_id: 1})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :body end)
      end
    end

    property "rejects empty string body" do
      check all(_ <- constant(:ok)) do
        cs = changeset(%{body: "", project_id: 1})
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
  end
end
