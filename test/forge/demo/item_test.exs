defmodule Forge.Demo.ItemTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Demo
  alias Forge.Demo.Item

  defp name_generator, do: string(:printable, min_length: 1, max_length: 200)

  describe "Item.changeset/2" do
    property "valid for any non-empty name" do
      check all(name <- name_generator()) do
        cs = Item.changeset(%Item{}, %{name: name})
        assert cs.valid?
        assert get_change(cs, :name) == name
      end
    end

    property "invalid when name is nil" do
      check all(extra <- string(:alphanumeric, min_length: 0, max_length: 10)) do
        cs = Item.changeset(%Item{}, %{name: nil, notes: extra})
        refute cs.valid?
        assert :name in Keyword.keys(cs.errors)
      end
    end

    property "invalid when name is missing" do
      check all(_extra <- integer()) do
        cs = Item.changeset(%Item{}, %{})
        refute cs.valid?
        assert :name in Keyword.keys(cs.errors)
      end
    end
  end

  describe "Demo context" do
    property "create_item/1 persists any valid name" do
      check all(name <- name_generator()) do
        assert {:ok, %Item{id: id, name: ^name}} = Demo.create_item(%{name: name})
        assert id != nil
      end
    end

    property "create_item/1 returns error changeset for nil name" do
      check all(_n <- integer(1..10)) do
        assert {:error, %Ecto.Changeset{}} = Demo.create_item(%{name: nil})
      end
    end

    property "get_item!/1 retrieves the created item" do
      check all(name <- name_generator()) do
        {:ok, item} = Demo.create_item(%{name: name})
        fetched = Demo.get_item!(item.id)
        assert fetched.id == item.id
        assert fetched.name == name
      end
    end

    property "update_item/2 persists a new name" do
      check all(
              old_name <- name_generator(),
              new_name <- name_generator()
            ) do
        {:ok, item} = Demo.create_item(%{name: old_name})
        assert {:ok, updated} = Demo.update_item(item, %{name: new_name})
        assert updated.name == new_name
      end
    end

    property "update_item/2 returns error changeset for nil name" do
      check all(name <- name_generator()) do
        {:ok, item} = Demo.create_item(%{name: name})
        assert {:error, %Ecto.Changeset{}} = Demo.update_item(item, %{name: nil})
        assert Demo.get_item!(item.id).name == name
      end
    end

    property "delete_item/1 removes the item" do
      check all(name <- name_generator()) do
        {:ok, item} = Demo.create_item(%{name: name})
        assert {:ok, _} = Demo.delete_item(item)
        assert_raise Ecto.NoResultsError, fn -> Demo.get_item!(item.id) end
      end
    end

    property "list_items/0 includes all created items" do
      check all(names <- list_of(name_generator(), min_length: 1, max_length: 4)) do
        before_ids = Demo.list_items() |> Enum.map(& &1.id) |> MapSet.new()

        created_ids =
          Enum.map(names, fn name ->
            {:ok, item} = Demo.create_item(%{name: name})
            item.id
          end)

        after_ids = Demo.list_items() |> Enum.map(& &1.id) |> MapSet.new()

        assert Enum.all?(created_ids, &MapSet.member?(after_ids, &1))
        assert MapSet.subset?(before_ids, after_ids)
      end
    end

    property "change_item/2 returns a changeset reflecting attrs" do
      check all(name <- name_generator()) do
        {:ok, item} = Demo.create_item(%{name: name})
        cs = Demo.change_item(item, %{name: "changed"})
        assert %Ecto.Changeset{} = cs
        assert get_change(cs, :name) == "changed"
      end
    end
  end
end
