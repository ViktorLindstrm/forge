defmodule Forge.Projects.Changes.CascadeTaskCompletion do
  @moduledoc """
  After a task's `:status` changes to `:done` or `:todo`:

  - If it is a **parent task** (no parent_task_id): sets all direct subtasks
    and their descendants to the same status, clearing pin_status.
  - If it is a **subtask**: checks whether all siblings are `:done` and, if so,
    marks the parent `:done`; otherwise marks the parent `:todo`.

  Applied as an `after_action` hook so we always work with persisted data.
  """
  use Ash.Resource.Change

  alias Forge.Projects.Task

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    case Ash.Changeset.fetch_change(changeset, :status) do
      {:ok, status} when status in [:done, :todo] ->
        Ash.Changeset.after_action(changeset, fn _changeset, task ->
          if is_nil(task.parent_task_id) do
            cascade_to_subtasks(task, status)
          else
            update_parent_status(task)
          end

          {:ok, task}
        end)

      _ ->
        changeset
    end
  end

  @spec cascade_to_subtasks(Task.t(), :done | :todo) :: :ok
  defp cascade_to_subtasks(%Task{id: task_id}, status) do
    subtasks =
      Task
      |> Ash.Query.filter(parent_task_id == ^task_id)
      |> Ash.read!()

    unless subtasks == [] do
      Task
      |> Ash.Query.filter(parent_task_id == ^task_id)
      |> Ash.bulk_update(:update, %{status: status, pin_status: nil},
        strategy: [:atomic, :stream],
        allow_stream_with: :full_read,
        transaction: false
      )

      Enum.each(subtasks, &cascade_to_subtasks(&1, status))
    end

    :ok
  end

  @spec update_parent_status(Task.t()) :: :ok
  defp update_parent_status(%Task{parent_task_id: nil}), do: :ok

  defp update_parent_status(%Task{parent_task_id: parent_id}) do
    parent = Ash.get!(Task, parent_id)

    siblings =
      Task
      |> Ash.Query.filter(parent_task_id == ^parent_id)
      |> Ash.read!()

    desired_status =
      if siblings != [] and Enum.all?(siblings, &(&1.status == :done)),
        do: :done,
        else: :todo

    if parent.status != desired_status do
      parent
      |> Ash.Changeset.for_update(:update, %{status: desired_status, pin_status: nil})
      |> Ash.update!()

      update_parent_status(parent)
    end

    :ok
  end
end
