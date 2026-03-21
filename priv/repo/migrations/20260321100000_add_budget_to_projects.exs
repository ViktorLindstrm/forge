defmodule Forge.Repo.Migrations.AddBudgetToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :budget, :numeric
    end
  end
end
