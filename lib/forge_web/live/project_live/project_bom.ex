defmodule ForgeWeb.ProjectLive.Bom do
  alias Forge.Projects

  @spec bom_form() :: Phoenix.HTML.Form.t()
  def bom_form do
    AshPhoenix.Form.for_create(Forge.Projects.BomItem, :create,
      domain: Projects,
      as: "bom"
    )
    |> Phoenix.Component.to_form()
  end

  @spec bom_edit_form(Forge.Projects.BomItem.t()) :: Phoenix.HTML.Form.t()
  def bom_edit_form(%Forge.Projects.BomItem{} = item) do
    AshPhoenix.Form.for_update(item, :update,
      domain: Projects,
      as: "bom_edit"
    )
    |> Phoenix.Component.to_form()
  end
end
