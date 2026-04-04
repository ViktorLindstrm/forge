defmodule Forge.Projects.Changes.CycleBomStatus do
  @moduledoc """
  Cycles a BOM item's status in order: `:needed` → `:ordered` → `:received` → `:needed`.
  """
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    new_status =
      case changeset.data.status do
        :needed -> :ordered
        :ordered -> :received
        _ -> :needed
      end

    Ash.Changeset.force_change_attribute(changeset, :status, new_status)
  end
end
