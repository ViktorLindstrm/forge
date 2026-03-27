defmodule Forge.Repo.Migrations.AddSortOrderToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :sort_order, :integer, null: false, default: 0
    end
  end
end
