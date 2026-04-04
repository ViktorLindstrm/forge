defmodule Forge.Projects.Changes.ToggleTaskDone do
  @moduledoc """
  Toggles a task's `:status` between `:done` and `:todo`.
  If the current status is `:done`, it becomes `:todo`; otherwise it becomes `:done`.
  """
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    new_status =
      case changeset.data.status do
        :done -> :todo
        _ -> :done
      end

    Ash.Changeset.force_change_attribute(changeset, :status, new_status)
  end
end
