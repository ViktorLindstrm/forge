defmodule Forge.Repo.Migrations.AddProjectGroupsAndTaskParentId do
  use Ecto.Migration

  def change do
    create table(:project_groups) do
      add :name, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_groups, [:name])

    alter table(:projects) do
      add :project_group_id, references(:project_groups, on_delete: :nilify_all)
    end

    create index(:projects, [:project_group_id])

    alter table(:tasks) do
      add :parent_task_id, references(:tasks, type: :binary_id, on_delete: :delete_all)
    end

    create index(:tasks, [:parent_task_id])
  end
end
