defmodule Forge.BomItem do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "bom_items"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :quantity, :integer, default: 1, allow_nil?: false, public?: true
    attribute :unit, :string, public?: true
    attribute :supplier, :string, public?: true
    attribute :link, :string, public?: true
    attribute :unit_price, :decimal, public?: true
    attribute :currency, :string, default: "SEK", public?: true
    attribute :status, Forge.BomStatus, default: :needed, allow_nil?: false, public?: true
    attribute :notes, :string, public?: true
    attribute :sort_order, :integer, default: 0, public?: true
    timestamps()
  end

  relationships do
    belongs_to :project, Forge.Project, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept([
        :name, :quantity, :unit, :supplier, :link,
        :unit_price, :currency, :status, :notes,
        :sort_order, :project_id
      ])
    end

    update :update do
      accept([
        :name, :quantity, :unit, :supplier, :link,
        :unit_price, :currency, :status, :notes, :sort_order
      ])
    end

    update :toggle_received do
      require_atomic? false
      change fn changeset, _ctx ->
        current = Ash.Changeset.get_attribute(changeset, :status)
        new_status = if current == :received, do: :needed, else: :received
        Ash.Changeset.change_attribute(changeset, :status, new_status)
      end
    end
  end

  code_interface do
    define :create, action: :create
    define :update, action: :update
    define :toggle_received, action: :toggle_received
    define :destroy, action: :destroy
  end
end
