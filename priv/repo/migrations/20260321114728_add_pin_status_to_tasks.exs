defmodule Forge.Repo.Migrations.AddPinStatusToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :pin_status, :text
    end

    create index(:tasks, [:project_id, :pin_status])
  end
end
