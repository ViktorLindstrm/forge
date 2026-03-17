defmodule Forge.TaskStatus do
  use Ash.Type.Enum,
    values: [:todo, :in_progress, :blocked, :done]
end
