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

  defp valid_attrs_generator do
    gen all(
          body <- body_generator(),
          title <- optional_title_generator()
        ) do
      base = %{"body" => body, "project_id" => 1}
      if title, do: Map.put(base, "title", title), else: base
    end
  end

  describe "changeset/2 with valid data" do
    property "accepts any non-empty body with project_id" do
      check all(attrs <- valid_attrs_generator()) do
        cs = JournalEntry.changeset(%JournalEntry{}, attrs)
        assert cs.valid?
      end
    end

    property "accepts body without a title (title is optional)" do
      check all(body <- body_generator()) do
        cs = JournalEntry.changeset(%JournalEntry{}, %{"body" => body, "project_id" => 1})
        assert cs.valid?
        assert is_nil(cs.errors[:title])
      end
    end

    property "accepts body with a title" do
      check all(
              body <- body_generator(),
              title <- string(:printable, min_length: 1, max_length: 200)
            ) do
        cs =
          JournalEntry.changeset(%JournalEntry{}, %{
            "body" => body,
            "title" => title,
            "project_id" => 1
          })

        assert cs.valid?
      end
    end
  end

  describe "changeset/2 with invalid data" do
    property "rejects missing body" do
      check all(title <- optional_title_generator()) do
        attrs =
          if title,
            do: %{"title" => title, "project_id" => 1},
            else: %{"project_id" => 1}

        cs = JournalEntry.changeset(%JournalEntry{}, attrs)
        refute cs.valid?
        assert :body in Keyword.keys(cs.errors)
      end
    end

    property "rejects nil body" do
      check all(title <- optional_title_generator()) do
        attrs =
          if title,
            do: %{"body" => nil, "title" => title, "project_id" => 1},
            else: %{"body" => nil, "project_id" => 1}

        cs = JournalEntry.changeset(%JournalEntry{}, attrs)
        refute cs.valid?
        assert :body in Keyword.keys(cs.errors)
      end
    end

    property "rejects empty string body (min length 1)" do
      check all(title <- optional_title_generator()) do
        attrs =
          if title,
            do: %{"body" => "", "title" => title, "project_id" => 1},
            else: %{"body" => "", "project_id" => 1}

        cs = JournalEntry.changeset(%JournalEntry{}, attrs)
        refute cs.valid?
        assert :body in Keyword.keys(cs.errors)
      end
    end

    property "rejects missing project_id" do
      check all(body <- body_generator()) do
        cs = JournalEntry.changeset(%JournalEntry{}, %{"body" => body})
        refute cs.valid?
        assert :project_id in Keyword.keys(cs.errors)
      end
    end

    property "rejects nil project_id" do
      check all(body <- body_generator()) do
        cs = JournalEntry.changeset(%JournalEntry{}, %{"body" => body, "project_id" => nil})
        refute cs.valid?
        assert :project_id in Keyword.keys(cs.errors)
      end
    end
  end
end
