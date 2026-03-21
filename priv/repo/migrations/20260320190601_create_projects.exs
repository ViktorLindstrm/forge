defmodule Forge.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:projects) do
      add :name, :string, null: false
      add :description, :text
      add :status, :string, default: "idea", null: false
      add :tech_stack, :string
      add :url, :string
      add :notes, :text
      add :color, :string, default: "blue", null: false

      timestamps(type: :utc_datetime)
    end
  end
end
