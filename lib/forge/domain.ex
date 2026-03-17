defmodule Forge.Domain do
  use Ash.Domain, otp_app: :forge

  resources do
    resource Forge.Category
    resource Forge.Project
    resource Forge.BomItem
    resource Forge.JournalEntry
    resource Forge.Attachment
    resource Forge.Task
    resource Forge.Tag
    resource Forge.TaskTag
  end
end
