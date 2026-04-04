defmodule ForgeWeb.ProjectLive.Tasks do
  @moduledoc """
  Form-builder helpers for task LiveView interactions.

  Provides `AshPhoenix.Form`-backed form structs for creating and editing
  `Forge.Projects.Task` records.  All task rendering lives in
  `ForgeWeb.ProjectLive.Components`.
  """

  use Phoenix.Component

  alias Forge.Projects
  alias Forge.Projects.Task

  @type project_id :: Projects.project_id()

  @spec task_form() :: Phoenix.HTML.Form.t()
  def task_form do
    AshPhoenix.Form.for_create(Task, :create,
      domain: Forge.Projects,
      as: "task"
    )
    |> Phoenix.Component.to_form()
  end

  @spec task_edit_form(Task.t()) :: Phoenix.HTML.Form.t()
  def task_edit_form(%Task{} = task) do
    AshPhoenix.Form.for_update(task, :update,
      domain: Forge.Projects,
      as: "task"
    )
    |> Phoenix.Component.to_form()
  end
end
