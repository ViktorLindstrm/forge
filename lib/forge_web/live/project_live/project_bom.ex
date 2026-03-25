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
end
