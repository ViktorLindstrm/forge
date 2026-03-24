defmodule Forge.Projects.Validations.TaskNotDone do
  @moduledoc """
  Validates that the task being acted upon is not in `:done` status.
  Used to prevent pinning of completed tasks.
  """
  use Ash.Resource.Validation

  @impl Ash.Resource.Validation
  def validate(changeset, _opts, _context) do
    current_status = changeset.data.status

    if current_status == :done do
      {:error, field: :pin_status, message: "cannot pin a done task"}
    else
      :ok
    end
  end

  @impl Ash.Resource.Validation
  def atomic(_changeset, _opts, _context) do
    {:not_atomic, "TaskNotDone requires checking persisted status"}
  end
end
