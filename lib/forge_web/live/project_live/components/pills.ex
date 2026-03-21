defmodule ForgeWeb.ProjectLive.Components.Pills do
  @moduledoc false

  use ForgeWeb, :html

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @type pill_kind :: String.t()

  defp pill_label("status", :in_progress), do: "In progress"
  defp pill_label("status", :blocked), do: "Blocked"
  defp pill_label("status", other), do: other |> to_string() |> String.capitalize()

  defp pill_label("priority", :low), do: "Low"
  defp pill_label("priority", :medium), do: "Medium"
  defp pill_label("priority", :high), do: "High"
  defp pill_label(_, value), do: value

  defp pill_classes("status", :in_progress),
    do: "bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300"

  defp pill_classes("status", :blocked),
    do: "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"

  defp pill_classes("status", _),
    do: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"

  defp pill_classes("priority", :low),
    do: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"

  defp pill_classes("priority", :medium),
    do: "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"

  defp pill_classes("priority", :high),
    do: "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-300"

  defp pill_classes(_, _), do: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"

  attr :kind, :string, required: true
  attr :value, :any, required: true

  @spec pill(assigns()) :: rendered()
  def pill(assigns) do
    assigns =
      assigns
      |> assign(:label, pill_label(assigns.kind, assigns.value))
      |> assign(:classes, pill_classes(assigns.kind, assigns.value))

    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-medium",
      @classes
    ]}>
      {@label}
    </span>
    """
  end
end
