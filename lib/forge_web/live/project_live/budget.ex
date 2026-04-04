defmodule ForgeWeb.ProjectLive.Budget do
  @moduledoc """
  Form-builder helpers for project budget LiveView interactions.

  Provides an `AshPhoenix.Form`-backed form struct for updating the budget
  fields on a `Forge.Projects.Project` record.
  """

  alias Forge.Projects

  @spec budget_form(Forge.Projects.Project.t()) :: Phoenix.HTML.Form.t()
  def budget_form(%Forge.Projects.Project{} = project) do
    AshPhoenix.Form.for_update(project, :update,
      domain: Projects,
      as: "project"
    )
    |> Phoenix.Component.to_form()
  end
end
