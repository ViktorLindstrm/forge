defmodule Forge.Category do
  use Ash.Resource,
    domain: Forge.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "categories"
    repo Forge.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :icon, :string, public?: true
    attribute :color, :string, public?: true
    timestamps()
  end

  identities do
    identity :unique_slug, [:slug]
  end

  actions do
    defaults [:read, :destroy, create: [:name, :slug, :icon, :color], update: [:name, :icon, :color]]
  end

  code_interface do
    define :list_all, action: :read
    define :get_by_id, action: :read, get_by: [:id]
  end
end
