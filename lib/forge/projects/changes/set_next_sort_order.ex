defmodule Forge.Projects.Changes.SetNextSortOrder do
  @moduledoc """
  Sets `sort_order` on creation to `max(sort_order) + 1` within the
  same project (or parent task for subtasks).

  Options:
    - `:filter_attribute` — the attribute to group by (e.g. `:project_id`). Required.
  """
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def init(opts) do
    case opts[:filter_attribute] do
      nil -> {:error, "SetNextSortOrder requires a :filter_attribute option"}
      _ -> {:ok, opts}
    end
  end

  @impl Ash.Resource.Change
  def change(changeset, opts, _context) do
    filter_attr = opts[:filter_attribute]

    case Ash.Changeset.get_attribute(changeset, filter_attr) do
      nil ->
        changeset

      filter_value ->
        max_order =
          changeset.resource
          |> Ash.Query.filter(^[{filter_attr, filter_value}])
          |> Ash.max!(:sort_order) || 0

        Ash.Changeset.force_change_attribute(changeset, :sort_order, max_order + 1)
    end
  end
end
