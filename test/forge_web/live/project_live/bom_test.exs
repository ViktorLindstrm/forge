defmodule ForgeWeb.ProjectLive.BomTest do
  use Forge.DataCase
  use ExUnitProperties

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Bom

  defp create_project! do
    {:ok, p} = Projects.create_project(%{"name" => "Bom #{System.unique_integer()}"})
    p
  end

  defp name_generator, do: string(:printable, min_length: 1, max_length: 100)

  defp positive_price_generator do
    map(positive_integer(), fn n -> to_string(n) <> ".00" end)
  end

  defp bom_status_generator do
    one_of(Enum.map(Projects.BomItem.statuses(), &constant/1))
  end

  defp valid_bom_params_generator do
    gen all(
          name <- name_generator(),
          qty <- integer(1..50),
          price <- positive_price_generator()
        ) do
      %{"bom" => %{"name" => name, "quantity" => to_string(qty), "unit_price" => price}}
    end
  end

  describe "handle_bom_create/2" do
    property "creates a BOM item and returns updated bom_budget assign" do
      check all(params <- valid_bom_params_generator()) do
        project = create_project!()

        assert {:ok, result} = Bom.handle_bom_create(params["bom"], project.id)
        assert is_list(result.assigns)
        assert Keyword.has_key?(result.assigns, :bom_budget)
        assert Keyword.has_key?(result.assigns, :bom_form)
        budget = Keyword.get(result.assigns, :bom_budget)
        assert Decimal.gt?(budget.total, Decimal.new(0))
      end
    end

    property "bom_form is reset to defaults after creation" do
      check all(params <- valid_bom_params_generator()) do
        project = create_project!()

        {:ok, result} = Bom.handle_bom_create(params["bom"], project.id)
        form = Keyword.get(result.assigns, :bom_form)
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.source.resource == Forge.Projects.BomItem
      end
    end

    property "returns error changeset when name is empty string" do
      check all(qty <- integer(1..10)) do
        project = create_project!()

        params = %{"name" => "  ", "quantity" => to_string(qty)}

        assert {:error, {:changeset, %Ash.Error.Invalid{}}} =
                 Bom.handle_bom_create(params, project.id)
      end
    end

    property "budget total grows with each item added" do
      check all(names <- list_of(name_generator(), min_length: 2, max_length: 4)) do
        project = create_project!()
        before_budget = Projects.bom_budget(project.id)

        Enum.each(names, fn name ->
          Bom.handle_bom_create(
            %{"name" => name, "quantity" => "1", "unit_price" => "5.00"},
            project.id
          )
        end)

        after_budget = Projects.bom_budget(project.id)
        assert Decimal.gt?(after_budget.total, before_budget.total)
      end
    end
  end

  describe "handle_bom_delete/2" do
    property "deletes item and budget decreases" do
      check all(name <- name_generator()) do
        project = create_project!()

        Bom.handle_bom_create(
          %{"name" => name, "quantity" => "1", "unit_price" => "10.00"},
          project.id
        )

        item = Projects.bom_budget(project.id).items |> List.last()

        before_budget = Projects.bom_budget(project.id)
        assert {:ok, result} = Bom.handle_bom_delete(%{"id" => item.id}, project.id)

        budget = Keyword.get(result.assigns, :bom_budget)
        assert Decimal.lt?(budget.total, before_budget.total)
      end
    end

    property "item no longer exists after delete" do
      check all(name <- name_generator()) do
        project = create_project!()

        Bom.handle_bom_create(
          %{"name" => name, "quantity" => "1", "unit_price" => "5.00"},
          project.id
        )

        item = Projects.bom_budget(project.id).items |> List.last()

        {:ok, _} = Bom.handle_bom_delete(%{"id" => item.id}, project.id)
        assert_raise Ash.Error.Invalid, fn -> Projects.get_bom_item!(item.id) end
      end
    end
  end

  describe "handle_bom_toggle/2" do
    property "cycles status: needed -> ordered -> received -> needed" do
      check all(name <- name_generator()) do
        project = create_project!()
        Bom.handle_bom_create(%{"name" => name, "quantity" => "1"}, project.id)
        item = Projects.bom_budget(project.id).items |> List.last()
        assert item.status == :needed

        {:ok, _} = Bom.handle_bom_toggle(%{"id" => item.id}, project.id)
        assert Projects.get_bom_item!(item.id).status == :ordered

        {:ok, _} = Bom.handle_bom_toggle(%{"id" => item.id}, project.id)
        assert Projects.get_bom_item!(item.id).status == :received

        {:ok, _} = Bom.handle_bom_toggle(%{"id" => item.id}, project.id)
        assert Projects.get_bom_item!(item.id).status == :needed
      end
    end

    property "spent budget increases when item moves to ordered/received" do
      check all(name <- name_generator()) do
        project = create_project!()

        Bom.handle_bom_create(
          %{"name" => name, "quantity" => "1", "unit_price" => "20.00"},
          project.id
        )

        item = Projects.bom_budget(project.id).items |> List.last()

        before_spent = Projects.bom_budget(project.id).spent
        {:ok, result} = Bom.handle_bom_toggle(%{"id" => item.id}, project.id)
        after_spent = Keyword.get(result.assigns, :bom_budget).spent

        assert Decimal.gt?(after_spent, before_spent)
      end
    end

    property "toggle result always contains updated bom_budget assign" do
      check all(
              name <- name_generator(),
              status <- bom_status_generator()
            ) do
        project = create_project!()

        {:ok, item} =
          Projects.create_bom_item(%{
            "name" => name,
            "project_id" => project.id,
            "status" => to_string(status)
          })

        assert {:ok, result} = Bom.handle_bom_toggle(%{"id" => item.id}, project.id)
        assert Keyword.has_key?(result.assigns, :bom_budget)
      end
    end
  end

  describe "bom_form/0" do
    test "returns a Phoenix.HTML.Form backed by AshPhoenix.Form" do
      form = Bom.bom_form()
      assert %Phoenix.HTML.Form{} = form
      assert %AshPhoenix.Form{} = form.source
      assert form.source.resource == Forge.Projects.BomItem
      assert form.name == "bom"
    end
  end
end
