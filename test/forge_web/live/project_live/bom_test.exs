defmodule ForgeWeb.ProjectLive.BomTest do
  use Forge.DataCase
  use ExUnitProperties

  alias ForgeWeb.ProjectLive.Bom
  alias Forge.Projects

  defp create_project! do
    {:ok, p} = Projects.create_project(%{"name" => "BomTest-#{System.unique_integer()}"})
    p
  end

  defp create_bom_item!(project, name, opts \\ %{}) do
    {:ok, item} =
      Projects.create_bom_item(
        Map.merge(%{"name" => name, "project_id" => project.id, "quantity" => 1}, opts)
      )

    item
  end

  defp name_generator, do: string(:alphanumeric, min_length: 1, max_length: 60)

  describe "bom_form/0" do
    property "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :create" do
      check all(_ <- constant(:ok)) do
        form = Bom.bom_form()
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.BomItem
        assert form.source.action == :create
        assert form.name == "bom"
      end
    end
  end

  describe "bom_edit_form/1" do
    property "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :update" do
      check all(name <- name_generator()) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.BomItem
        assert form.source.action == :update
        assert form.name == "bom_edit"
      end
    end

    property "form fields are pre-populated with existing item values" do
      check all(
              name <- name_generator(),
              quantity <- positive_integer()
            ) do
        project = create_project!()
        item = create_bom_item!(project, name, %{"quantity" => quantity})
        form = Bom.bom_edit_form(item)

        assert Phoenix.HTML.Form.input_value(form, :name) == name
        assert Phoenix.HTML.Form.input_value(form, :quantity) == quantity
      end
    end

    property "form pre-populates optional fields when set" do
      check all(
              name <- name_generator(),
              unit <- string(:alphanumeric, min_length: 1, max_length: 10),
              supplier <- string(:alphanumeric, min_length: 1, max_length: 50)
            ) do
        project = create_project!()
        item = create_bom_item!(project, name, %{"unit" => unit, "supplier" => supplier})
        form = Bom.bom_edit_form(item)

        assert Phoenix.HTML.Form.input_value(form, :unit) == unit
        assert Phoenix.HTML.Form.input_value(form, :supplier) == supplier
      end
    end

    property "validate/2 returns errors for blank name" do
      check all(name <- name_generator()) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        validated =
          AshPhoenix.Form.validate(form.source, %{"name" => ""})
          |> Phoenix.Component.to_form()

        assert validated.source.source.valid? == false
      end
    end

    property "validate/2 accepts updated name" do
      check all(
              name <- name_generator(),
              new_name <- name_generator()
            ) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        validated =
          AshPhoenix.Form.validate(form.source, %{"name" => new_name})
          |> Phoenix.Component.to_form()

        assert validated.source.source.valid?
      end
    end

    property "submit/2 updates item name in database" do
      check all(
              name <- name_generator(),
              new_name <- name_generator()
            ) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        {:ok, updated} =
          AshPhoenix.Form.submit(form.source, params: %{"name" => new_name, "quantity" => "1"})

        assert updated.name == new_name
        assert updated.id == item.id
      end
    end

    property "submit/2 updates quantity" do
      check all(
              name <- name_generator(),
              new_qty <- positive_integer()
            ) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        {:ok, updated} =
          AshPhoenix.Form.submit(form.source,
            params: %{"name" => name, "quantity" => to_string(new_qty)}
          )

        assert updated.quantity == new_qty
      end
    end

    property "submit/2 updates unit_price" do
      check all(
              name <- name_generator(),
              whole <- non_negative_integer(),
              frac <- integer(0..99)
            ) do
        price_str = "#{whole}.#{String.pad_leading(to_string(frac), 2, "0")}"
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        {:ok, updated} =
          AshPhoenix.Form.submit(form.source,
            params: %{"name" => name, "quantity" => "1", "unit_price" => price_str}
          )

        assert Decimal.equal?(updated.unit_price, Decimal.new(price_str))
      end
    end

    property "submit/2 returns error form when name is blank" do
      check all(name <- name_generator()) do
        project = create_project!()
        item = create_bom_item!(project, name)
        form = Bom.bom_edit_form(item)

        {:error, _form} =
          AshPhoenix.Form.submit(form.source, params: %{"name" => "", "quantity" => "1"})
      end
    end
  end
end
