defmodule ForgeWeb.SharedHelpers do
  @moduledoc """
  Delade hjälpfunktioner som används av flera komponentmoduler.
  Badges och statuses hanteras av UIComponents.
  """

  def hero_bg(nil),                    do: "bg-zinc-700"
  def hero_bg(%{slug: "3d_printing"}), do: "bg-gradient-to-br from-orange-900 to-orange-700"
  def hero_bg(%{slug: "programming"}), do: "bg-gradient-to-br from-indigo-900 to-indigo-700"
  def hero_bg(%{slug: "electronics"}), do: "bg-gradient-to-br from-emerald-900 to-emerald-700"
  def hero_bg(%{slug: "home"}),        do: "bg-gradient-to-br from-amber-900 to-amber-700"
  def hero_bg(_),                      do: "bg-zinc-700"

  def cover_url(%{cover_image_id: nil}), do: nil
  def cover_url(%{attachments: atts, cover_image_id: id}) when is_list(atts) do
    case Enum.find(atts, &(to_string(&1.id) == to_string(id))) do
      nil -> nil
      att -> Forge.Storage.url(att.storage_path)
    end
  end
  def cover_url(_), do: nil

  def bom_received(items), do: Enum.count(items, &(&1.status == :received))

  def bom_total(items) do
    items
    |> Enum.reduce(Decimal.new(0), fn item, acc ->
      if item.unit_price,
        do: Decimal.add(acc, Decimal.mult(item.unit_price, item.quantity)),
        else: acc
    end)
    |> Decimal.round(0)
  end

  def bom_status_icon(:needed),     do: "hero-clock"
  def bom_status_icon(:ordered),    do: "hero-truck"
  def bom_status_icon(:received),   do: "hero-check-circle"
  def bom_status_icon(:not_needed), do: "hero-no-symbol"
  def bom_status_icon(_),           do: "hero-clock"

  def bom_status_icon_cls(:needed),     do: "text-zinc-400"
  def bom_status_icon_cls(:ordered),    do: "text-blue-500"
  def bom_status_icon_cls(:received),   do: "text-emerald-500"
  def bom_status_icon_cls(:not_needed), do: "text-zinc-300"
  def bom_status_icon_cls(_),           do: "text-zinc-400"

  def bom_status_lbl(:needed),     do: "Behövs"
  def bom_status_lbl(:ordered),    do: "Beställd"
  def bom_status_lbl(:received),   do: "Inköpt"
  def bom_status_lbl(:not_needed), do: "Behövs ej"
  def bom_status_lbl(_),           do: "Behövs"

  def entry_icon(%{body: body}) when is_binary(body) do
    cond do
      String.contains?(body, ":::bom")    -> "📦"
      String.contains?(body, ":::status") -> "📋"
      String.contains?(body, ":::image")  -> "🖼️"
      true                                -> "📝"
    end
  end
  def entry_icon(_), do: "📝"

  def upload_icon("image/" <> _),              do: "🖼️"
  def upload_icon("application/pdf"),          do: "📄"
  def upload_icon("model/stl"),                do: "⬡"
  def upload_icon("application/octet-stream"), do: "⬡"
  def upload_icon("text/yaml"),                do: "⚙️"
  def upload_icon("text/x-yaml"),              do: "⚙️"
  def upload_icon(_),                          do: "📎"

  def due_label(nil), do: nil
  def due_label(date) do
    today = Date.utc_today()
    if Date.compare(date, today) == :eq, do: "idag", else: Calendar.strftime(date, "%d %b")
  end

  def due_cls(nil), do: ""
  def due_cls(date) do
    today = Date.utc_today()
    case Date.compare(date, today) do
      :lt -> "text-red-500"
      :eq -> "text-amber-600"
      _   -> "text-zinc-400"
    end
  end
end
