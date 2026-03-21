defmodule Forge.Repo.Migrations.AddSortOrderToJournalEntries do
  use Ecto.Migration

  def change do
    alter table(:journal_entries) do
      add :sort_order, :integer, null: false, default: 0
    end
  end
end
