defmodule Forge.BomStatus do
  use Ash.Type.Enum,
    values: [:needed, :ordered, :received, :not_needed]
end
