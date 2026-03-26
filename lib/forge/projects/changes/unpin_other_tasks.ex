defmodule Forge.Projects.Changes.UnpinOtherTasks do
  @moduledoc """
  When a task's `pin_status` is being set to `:current` or `:upcoming`,
  clears that same pin slot for all other tasks in the same project.
  """
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    case Ash.Changeset.fetch_change(changeset, :pin_status) do
      {:ok, pin_status} when pin_status in [:current, :upcoming] ->
        project_id = Ash.Changeset.get_attribute(changeset, :project_id)
        task_id = changeset.data.id

        Ash.Changeset.after_action(changeset, fn _changeset, task ->
          changeset.resource
          |> Ash.Query.filter(
            project_id == ^project_id and
              pin_status == ^pin_status and
              id != ^task_id
          )
          |> Ash.bulk_update(:update, %{pin_status: nil},
            strategy: [:atomic, :stream],
            allow_stream_with: :full_read,
            transaction: false
          )

          {:ok, task}
        end)

      _ ->
        changeset
    end
  end
end
