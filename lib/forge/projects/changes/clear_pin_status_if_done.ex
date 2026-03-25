defmodule Forge.Projects.Changes.ClearPinStatusIfDone do
  @moduledoc """
  Clears `pin_status` when `status` is being changed to `:done`.
  """
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    case Ash.Changeset.fetch_change(changeset, :status) do
      {:ok, :done} ->
        Ash.Changeset.force_change_attribute(changeset, :pin_status, nil)

      _ ->
        changeset
    end
  end

  @impl Ash.Resource.Change
  def atomic(changeset, _opts, _context) do
    case Ash.Changeset.fetch_change(changeset, :status) do
      {:ok, :done} ->
        {:ok, Ash.Changeset.atomic_update(changeset, :pin_status, {:const, nil})}

      _ ->
        {:ok, changeset}
    end
  end
end
