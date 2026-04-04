defmodule ForgeWeb.ProjectLive.Components.Pills do
  @moduledoc false

  use ForgeWeb, :html

  @spec pill_label(String.t(), atom()) :: String.t()
  defp pill_label("status", :in_progress), do: "In progress"
  defp pill_label("status", :blocked), do: "Blocked"
  defp pill_label("status", other), do: other |> to_string() |> String.capitalize()
  defp pill_label("priority", :low), do: "Low"
  defp pill_label("priority", :medium), do: "Medium"
  defp pill_label("priority", :high), do: "High"
  defp pill_label(_, value), do: to_string(value)

  @spec pill_color(String.t(), atom()) :: String.t()
  defp pill_color("status", :in_progress), do: "primary"
  defp pill_color("status", :blocked), do: "warning"
  defp pill_color("status", _), do: "gray"
  defp pill_color("priority", :low), do: "gray"
  defp pill_color("priority", :medium), do: "info"
  defp pill_color("priority", :high), do: "danger"
  defp pill_color(_, _), do: "gray"

  attr :kind, :string, required: true
  attr :value, :any, required: true

  @spec pill(map()) :: Phoenix.LiveView.Rendered.t()
  def pill(assigns) do
    assigns =
      assigns
      |> assign(:label, pill_label(assigns.kind, assigns.value))
      |> assign(:color, pill_color(assigns.kind, assigns.value))

    ~H"""
    <.badge color={@color} variant="soft" size="xs">{@label}</.badge>
    """
  end
end
