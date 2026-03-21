defmodule ForgeWeb.ProjectLive.Bom do
  alias Forge.Projects
  alias Forge.Projects.BomItem

  alias ForgeWeb.ProjectLive.Result

  @type project_id :: pos_integer()

  @type bom_params :: %{
          required(String.t()) => String.t() | number() | nil
        }

  @type handler_result ::
          Result.ok(BomItem.t())
          | Result.error_changeset()
          | {:error, :could_not_update}

  defdelegate create_bom_item(attrs), to: Projects, as: :create_bom_item
  defdelegate delete_bom_item(item), to: Projects, as: :delete_bom_item
  defdelegate update_bom_item(item, attrs), to: Projects, as: :update_bom_item
  defdelegate bom_budget(project_id), to: Projects, as: :bom_budget

  @spec handle_bom_create(bom_params(), project_id()) ::
          Result.ok(BomItem.t()) | Result.error_changeset()
  def handle_bom_create(params, project_id) do
    params = sanitize_bom_params(params)

    case create_bom_item(Map.put(params, "project_id", project_id)) do
      {:ok, _item} ->
        {:ok,
         %{
           assigns: [
             bom_budget: bom_budget(project_id),
             bom_form: Phoenix.Component.to_form(bom_params(), as: :bom)
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

  @spec bom_params() :: %{
          required(String.t()) => String.t() | pos_integer()
        }
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

  @spec sanitize_bom_params(bom_params()) :: map()
  defp sanitize_bom_params(params) do
    params
    |> Map.update("name", "", &String.trim/1)
    |> Map.update("quantity", 1, fn
      "" -> 1
      v when is_binary(v) -> String.to_integer(v)
      v -> v
    end)
    |> Map.update("unit_price", nil, fn
      "" -> nil
      v when is_binary(v) -> Decimal.new(v)
      %Decimal{} = v -> v
      v -> v
    end)
    |> Map.update("unit", nil, fn
      "" -> nil
      v -> v
    end)
    |> Map.update("supplier", nil, fn
      "" -> nil
      v -> v
    end)
    |> Map.update("link", nil, fn
      "" -> nil
      v -> v
    end)
    |> Map.update("notes", nil, fn
      "" -> nil
      v -> v
    end)
    |> Map.put_new("status", :needed)
    |> Map.put_new("currency", "SEK")
  end
end
