defmodule Forge.Projects.Preparations.SortTasksByPin do
  @moduledoc """
  Orders tasks by: pinned (current first, upcoming second), then sort_order, then inserted_at.
  """
  use Ash.Resource.Preparation

  require Ash.Expr

  @impl Ash.Resource.Preparation
  def prepare(query, _opts, _context) do
    Ash.Query.sort(query, [
      {Ash.Expr.calc(
         if pin_status == :current do
           0
         else
           if pin_status == :upcoming do
             1
           else
             2
           end
         end,
         type: :integer
       ), :asc},
      {:sort_order, :asc},
      {:inserted_at, :asc}
    ])
  end
end
