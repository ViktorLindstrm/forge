defmodule Forge.Demo do
  @moduledoc """
  The Demo context.
  """

  import Ecto.Query, warn: false
  alias Forge.Repo
  alias Forge.Demo.Item

  @type item_id :: integer()

  @spec list_items() :: [Item.t()]
  def list_items do
    Repo.all(Item)
  end

  @spec get_item!(item_id()) :: Item.t()
  def get_item!(id), do: Repo.get!(Item, id)

  @spec create_item(map()) :: {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def create_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_item(Item.t(), map()) :: {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_item(Item.t()) :: {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @spec change_item(Item.t(), map()) :: Ecto.Changeset.t()
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end
end
