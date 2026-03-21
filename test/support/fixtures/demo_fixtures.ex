defmodule Forge.DemoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Forge.Demo` context.
  """

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Forge.Demo.create_item()

    item
  end
end
