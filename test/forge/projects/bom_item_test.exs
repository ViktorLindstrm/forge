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

  defp valid_attrs_generator do
    gen all(
          name <- name_generator(),
          quantity <- positive_quantity_generator(),
          status <- one_of(Enum.map(@statuses, &constant/1))
        ) do
      %{
        "name" => name,
        "quantity" => quantity,
        "status" => to_string(status),
        "project_id" => 1
      }
    end
  end

  describe "changeset/2 with valid data" do
    property "accepts valid name, quantity and project_id" do
      check all(attrs <- valid_attrs_generator()) do
        cs = BomItem.changeset(%BomItem{}, attrs)
        assert cs.valid?
      end
    end

    property "accepts all valid status values" do
      check all(
              status <- one_of(Enum.map(@statuses, &constant/1)),
              name <- name_generator()
            ) do
        cs =
          BomItem.changeset(%BomItem{}, %{
            "name" => name,
            "project_id" => 1,
            "status" => to_string(status)
          })

        assert cs.valid?
      end
    end

    property "accepts positive unit_price as string decimal" do
      check all(
              whole <- non_negative_integer(),
              frac <- integer(0..99),
              name <- name_generator()
            ) do
        price_str = "#{whole}.#{String.pad_leading(to_string(frac), 2, "0")}"

        cs =
          BomItem.changeset(%BomItem{}, %{
            "name" => name,
            "project_id" => 1,
            "unit_price" => price_str
          })

        assert cs.valid?
      end
    end

    property "accepts optional text fields (unit, supplier, link, notes)" do
      check all(
              name <- name_generator(),
              extra <- string(:printable, min_length: 0, max_length: 100)
            ) do
        cs =
          BomItem.changeset(%BomItem{}, %{
            "name" => name,
            "project_id" => 1,
            "unit" => extra,
            "supplier" => extra,
            "link" => extra,
            "notes" => extra
          })

        assert cs.valid?
      end
    end

    property "accepts any non-negative sort_order" do
      check all(
              sort_order <- non_negative_integer(),
              name <- name_generator()
            ) do
        cs =
          BomItem.changeset(%BomItem{}, %{
            "name" => name,
            "project_id" => 1,
            "sort_order" => sort_order
          })

        assert cs.valid?
      end
    end
  end

  describe "changeset/2 with invalid data" do
    property "rejects missing name" do
      check all(attrs <- valid_attrs_generator()) do
        cs = BomItem.changeset(%BomItem{}, Map.delete(attrs, "name"))
        refute cs.valid?
        assert :name in Keyword.keys(cs.errors)
      end
    end

    property "rejects nil name" do
      check all(attrs <- valid_attrs_generator()) do
        cs = BomItem.changeset(%BomItem{}, Map.put(attrs, "name", nil))
        refute cs.valid?
        assert :name in Keyword.keys(cs.errors)
      end
    end

    property "rejects missing project_id" do
      check all(name <- name_generator()) do
        cs = BomItem.changeset(%BomItem{}, %{"name" => name})
        refute cs.valid?
        assert :project_id in Keyword.keys(cs.errors)
      end
    end

    property "rejects quantity of zero" do
      check all(name <- name_generator()) do
        cs = BomItem.changeset(%BomItem{}, %{"name" => name, "project_id" => 1, "quantity" => 0})
        refute cs.valid?
        assert :quantity in Keyword.keys(cs.errors)
      end
    end

    property "rejects negative quantity" do
      check all(
              quantity <- map(positive_integer(), &(-&1)),
              name <- name_generator()
            ) do
        cs =
          BomItem.changeset(%BomItem{}, %{
            "name" => name,
            "project_id" => 1,
            "quantity" => quantity
          })

        refute cs.valid?
        assert :quantity in Keyword.keys(cs.errors)
      end
    end
  end

  describe "statuses/0" do
    test "returns all expected statuses" do
      assert BomItem.statuses() == @statuses
    end
  end
end
