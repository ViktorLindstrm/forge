defmodule Forge.AttachmentType do
  use Ash.Type.Enum,
    values: [:image, :model, :config, :schematic, :document, :misc]
end
