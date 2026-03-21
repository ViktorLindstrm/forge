defmodule Forge.Repo.Migrations.AddFieldsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add_if_not_exists :tech_stack, :string
      add_if_not_exists :url, :string
      add_if_not_exists :notes, :text
      add_if_not_exists :color, :string, default: "blue"
    end

    drop_if_exists index(:projects, [:category_id])

    alter table(:projects) do
      remove_if_exists :category_id
      remove_if_exists :cover_image_id
    end

    execute "DELETE FROM schema_migrations WHERE version = '20260320190601'"
  end
end
