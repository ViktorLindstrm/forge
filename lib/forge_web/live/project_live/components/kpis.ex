defmodule ForgeWeb.ProjectLive.Components.Kpis do
  @moduledoc false

  use ForgeWeb, :html

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :tone, :string, required: true

  @spec mini_kpi(assigns()) :: rendered()
  def mini_kpi(assigns) do
    ~H"""
    <div class={["rounded-xl border p-3", mini_kpi_border(@tone), mini_kpi_bg(@tone)]}>
      <p class="text-[11px] font-medium text-gray-500 dark:text-gray-400">{@label}</p>
      <p class={["text-sm font-semibold mt-0.5 tabular-nums", mini_kpi_text(@tone)]}>
        {@value}
      </p>
    </div>
    """
  end

  defp mini_kpi_border("emerald"), do: "border-emerald-100 dark:border-emerald-900/40"
  defp mini_kpi_border("amber"), do: "border-amber-100 dark:border-amber-900/40"
  defp mini_kpi_border("slate"), do: "border-gray-100 dark:border-gray-800"
  defp mini_kpi_border(_), do: "border-gray-100 dark:border-gray-800"

  defp mini_kpi_bg("emerald"), do: "bg-emerald-50/60 dark:bg-emerald-950/20"
  defp mini_kpi_bg("amber"), do: "bg-amber-50/60 dark:bg-amber-950/20"
  defp mini_kpi_bg("slate"), do: "bg-gray-50/60 dark:bg-gray-950/20"
  defp mini_kpi_bg(_), do: "bg-gray-50/60 dark:bg-gray-950/20"

  defp mini_kpi_text("emerald"), do: "text-emerald-700 dark:text-emerald-300"
  defp mini_kpi_text("amber"), do: "text-amber-700 dark:text-amber-300"
  defp mini_kpi_text("slate"), do: "text-gray-700 dark:text-gray-200"
  defp mini_kpi_text(_), do: "text-gray-700 dark:text-gray-200"
end
