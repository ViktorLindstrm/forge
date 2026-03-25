defmodule Forge.Projects.Preparations.SortProjectsByStatus do
  @moduledoc """
  Orders projects by status priority (active → idea → paused → done), then by name.
  """
  use Ash.Resource.Preparation

  require Ash.Expr

  @impl Ash.Resource.Preparation
  def prepare(query, _opts, _context) do
    Ash.Query.sort(query, [
      {Ash.Expr.calc(
         cond do
           status == :active -> 0
           status == :idea -> 1
           status == :paused -> 2
           true -> 3
         end,
         type: :integer
       ), :asc},
      {:name, :asc}
    ])
  end
end
