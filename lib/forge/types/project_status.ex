defmodule Forge.ProjectStatus do
  use Ash.Type.Enum,
    values: [:idea, :active, :on_hold, :done, :abandoned]
end
