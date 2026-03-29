defmodule Forge.Repo.Migrations.AddTasksEnabledToProjects do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE projects ADD COLUMN IF NOT EXISTS tasks_enabled boolean DEFAULT false NOT NULL"
    )
  end
end
