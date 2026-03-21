defmodule Forge.Repo.Migrations.CreateProjectSubresources do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :title, :text, null: false
      add :status, :text, null: false, default: "todo"
      add :priority, :text, null: false, default: "medium"
      add :due_date, :date
      add :sort_order, :integer, null: false, default: 0
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:bom_items, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :quantity, :integer, null: false, default: 1
      add :unit, :text
      add :supplier, :text
      add :link, :text
      add :unit_price, :numeric
      add :currency, :text, null: false, default: "SEK"
      add :status, :text, null: false, default: "needed"
      add :notes, :text
      add :sort_order, :integer, null: false, default: 0
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:journal_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :title, :text
      add :body, :text, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
