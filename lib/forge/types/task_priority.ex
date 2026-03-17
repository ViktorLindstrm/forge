defmodule Forge.TaskPriority do
  use Ash.Type.Enum,
    values: [:low, :medium, :high]
end
