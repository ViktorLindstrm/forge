defmodule Forge.Repo.Migrations.MigrateToAshResourcesFinal do
  @moduledoc """
  Records existing tables as Ash-managed resources.
  Tables already exist from prior Ecto migrations; this migration is intentionally a no-op.
  """

  use Ecto.Migration

  def up, do: :ok
  def down, do: :ok
end
