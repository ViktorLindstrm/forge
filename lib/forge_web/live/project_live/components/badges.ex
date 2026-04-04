defmodule ForgeWeb.ProjectLive.Components.Badges do
  @moduledoc false

  use ForgeWeb, :html

  attr :status, :any, required: true

  @spec status_badge(map()) :: Phoenix.LiveView.Rendered.t()
  def status_badge(assigns) do
    assigns = assign(assigns, :badge_color, status_color(assigns.status))

    ~H"""
    <.badge
      color={@badge_color}
      variant="soft"
      role="status"
      class="shrink-0 inline-flex items-center gap-1"
    >
      <span class={["size-1.5 rounded-full", status_dot(@status)]} />
      {String.capitalize(to_string(@status))}
    </.badge>
    """
  end

  @spec status_color(Forge.Projects.Project.status()) :: String.t()
  defp status_color(:active), do: "success"
  defp status_color(:idea), do: "primary"
  defp status_color(:paused), do: "warning"
  defp status_color(:done), do: "info"
  defp status_color(_), do: "gray"

  @spec status_dot(Forge.Projects.Project.status()) :: String.t()
  defp status_dot(:active), do: "bg-emerald-500"
  defp status_dot(:idea), do: "bg-violet-500"
  defp status_dot(:paused), do: "bg-amber-500"
  defp status_dot(:done), do: "bg-blue-500"
  defp status_dot(_), do: "bg-gray-400"

  @spec color_bg(Forge.Projects.Project.color()) :: String.t()
  def color_bg(:blue), do: "bg-gradient-to-r from-blue-300 via-blue-500 to-blue-600"
  def color_bg(:violet), do: "bg-gradient-to-r from-violet-300 via-violet-500 to-violet-600"
  def color_bg(:emerald), do: "bg-gradient-to-r from-emerald-300 via-emerald-500 to-emerald-600"
  def color_bg(:amber), do: "bg-gradient-to-r from-amber-300 via-amber-500 to-amber-600"
  def color_bg(:rose), do: "bg-gradient-to-r from-rose-300 via-rose-500 to-rose-600"
  def color_bg(:orange), do: "bg-gradient-to-r from-orange-300 via-orange-500 to-orange-600"
  def color_bg(:sky), do: "bg-gradient-to-r from-sky-300 via-sky-500 to-sky-600"
  def color_bg(_), do: "bg-gradient-to-r from-gray-200 via-gray-400 to-gray-500"

  @spec url_display(String.t()) :: String.t()
  defdelegate url_display(url), to: ForgeWeb.ProjectLive.Components.Formatting
end
