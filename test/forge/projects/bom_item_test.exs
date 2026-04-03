defmodule Forge.Projects.BomItemTest do
  use Forge.DataCase, async: true
  use ExUnitProperties

  alias Forge.Projects.BomItem

  @statuses [:needed, :ordered, :received]

  defp name_generator do
    string(:printable, min_length: 1, max_length: 200)
  end

  defp positive_quantity_generator do
    positive_integer()
  end

  defp changeset(attrs) do
    Ash.Changeset.for_create(BomItem, :create, attrs)
  end

  describe "for_create/3 with valid data" do
    property "accepts valid name, quantity and project_id" do
      check all(
              name <- name_generator(),
              quantity <- positive_quantity_generator(),
              status <- one_of(Enum.map(@statuses, &constant/1))
            ) do
        cs = changeset(%{name: name, quantity: quantity, status: status, project_id: 1})
        assert cs.valid?
      end
    end

    property "accepts all valid status values" do
      check all(
              status <- one_of(Enum.map(@statuses, &constant/1)),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, project_id: 1, status: status})
        assert cs.valid?
      end
    end

    property "accepts positive unit_price as decimal" do
      check all(
              whole <- non_negative_integer(),
              frac <- integer(0..99),
              name <- name_generator()
            ) do
        price = Decimal.new("#{whole}.#{String.pad_leading(to_string(frac), 2, "0")}")
        cs = changeset(%{name: name, project_id: 1, unit_price: price})
        assert cs.valid?
      end
    end

    property "accepts optional text fields (unit, supplier, link, notes)" do
      check all(
              name <- name_generator(),
              extra <- string(:printable, min_length: 0, max_length: 100)
            ) do
        cs =
          changeset(%{
            name: name,
            project_id: 1,
            unit: extra,
            supplier: extra,
            link: extra,
            notes: extra
          })

        assert cs.valid?
      end
    end

    property "accepts any non-negative sort_order" do
      check all(
              sort_order <- non_negative_integer(),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, project_id: 1, sort_order: sort_order})
        assert cs.valid?
      end
    end
  end

  describe "for_create/3 with invalid data" do
    property "rejects missing name" do
      check all(quantity <- positive_quantity_generator()) do
        cs = changeset(%{quantity: quantity, project_id: 1})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :name end)
      end
    end

    property "rejects nil name" do
      check all(quantity <- positive_quantity_generator()) do
        cs = changeset(%{name: nil, quantity: quantity, project_id: 1})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :name end)
      end
    end

    property "rejects missing project_id" do
      check all(name <- name_generator()) do
        cs = changeset(%{name: name})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :project_id end)
      end
    end

    property "rejects quantity of zero" do
      check all(name <- name_generator()) do
        cs = changeset(%{name: name, project_id: 1, quantity: 0})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :quantity end)
      end
    end

    property "rejects negative quantity" do
      check all(
              quantity <- map(positive_integer(), &(-&1)),
              name <- name_generator()
            ) do
        cs = changeset(%{name: name, project_id: 1, quantity: quantity})
        refute cs.valid?
        assert Enum.any?(cs.errors, fn e -> e.field == :quantity end)
      end
    end
  end

  describe "statuses/0" do
    property "returns all expected statuses" do
      check all(_ <- constant(:ok)) do
        assert BomItem.statuses() == @statuses
      end
    end
  end
end
