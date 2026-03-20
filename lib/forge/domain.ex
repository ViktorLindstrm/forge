defmodule Forge.Domain do
  use Ash.Domain,
    otp_app: :forge,
    extensions: [AshJsonApi.Domain]

  json_api do
    base_route "/api"
  end

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
