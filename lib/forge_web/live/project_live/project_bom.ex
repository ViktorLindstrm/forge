defmodule ForgeWeb.ProjectLive.Bom do
  alias Forge.Projects
  alias Forge.Projects.BomItem

  alias ForgeWeb.ProjectLive.Result

  @type project_id :: Projects.project_id()

  defdelegate create_bom_item(attrs), to: Projects, as: :create_bom_item
  defdelegate delete_bom_item(item), to: Projects, as: :delete_bom_item
  defdelegate update_bom_item(item, attrs), to: Projects, as: :update_bom_item
  defdelegate bom_budget(project_id), to: Projects, as: :bom_budget

  @spec handle_bom_create(map(), project_id()) ::
          Result.ok(BomItem.t()) | Result.error_changeset()
  def handle_bom_create(params, project_id) do
    case create_bom_item(Map.put(params, "project_id", project_id)) do
      {:ok, _item} ->
        {:ok,
         %{
           assigns: [
             bom_budget: bom_budget(project_id),
             bom_form: bom_form()
           ]
         }}

      {:error, changeset} ->
        {:error, {:changeset, changeset}}
    end
  end

  @spec handle_bom_delete(%{required(String.t()) => String.t()}, project_id()) ::
          Result.ok(BomItem.t())
  def handle_bom_delete(%{"id" => id}, project_id) do
    item = Projects.get_bom_item!(id)
    {:ok, _} = delete_bom_item(item)

    {:ok, %{assigns: [bom_budget: bom_budget(project_id)]}}
  end

  @spec handle_bom_toggle(%{required(String.t()) => String.t()}, project_id()) ::
          Result.ok(BomItem.t()) | {:error, :could_not_update}
  def handle_bom_toggle(%{"id" => id}, project_id) do
    item = Projects.get_bom_item!(id)

    new_status =
      case item.status do
        :needed -> :ordered
        :ordered -> :received
        _ -> :needed
      end

    case update_bom_item(item, %{status: new_status}) do
      {:ok, _item} ->
        {:ok, %{assigns: [bom_budget: bom_budget(project_id)]}}

      {:error, _changeset} ->
        {:error, :could_not_update}
    end
  end

  @spec bom_form() :: Phoenix.HTML.Form.t()
  def bom_form do
    AshPhoenix.Form.for_create(BomItem, :create,
      domain: Projects,
      as: "bom"
    )
    |> Phoenix.Component.to_form()
  end

  @deprecated "Use bom_form/0 instead"
  @spec bom_params() :: %{String.t() => String.t() | pos_integer()}
  def bom_params do
    %{
      "name" => "",
      "quantity" => 1,
      "unit" => "",
      "unit_price" => "",
      "supplier" => "",
      "link" => "",
      "notes" => "",
      "status" => "needed"
    }
  end
end
