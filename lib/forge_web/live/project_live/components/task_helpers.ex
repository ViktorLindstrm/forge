defmodule ForgeWeb.ProjectLive.Components.TaskHelpers do
  @moduledoc false

  @spec task_progress_label(Forge.Projects.task_stats()) :: String.t()
  def task_progress_label(counts) do
    total = counts |> Map.values() |> Enum.sum()
    done = Map.get(counts, :done, 0)

    cond do
      total == 0 ->
        "No tasks yet"

      done == total ->
        "All done"

      true ->
        percent = Float.round(done / total * 100, 0) |> trunc()
        "#{done}/#{total} done (#{percent}%)"
    end
  end
end
