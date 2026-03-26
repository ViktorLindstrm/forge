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
    if opts[:filter_attribute] do
      {:ok, opts}
    else
      {:error, "SetNextSortOrder requires a :filter_attribute option"}
    end
  end

  @impl Ash.Resource.Change
  def change(changeset, opts, _context) do
    filter_attr = opts[:filter_attribute]
    filter_value = Ash.Changeset.get_attribute(changeset, filter_attr)

    if is_nil(filter_value) do
      changeset
    else
      max_order =
        changeset.resource
        |> Ash.Query.filter(^[{filter_attr, filter_value}])
        |> Ash.max!(:sort_order) || 0

      Ash.Changeset.force_change_attribute(changeset, :sort_order, max_order + 1)
    end
  end
end
