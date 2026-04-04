defmodule ForgeWeb.ProjectLive.Components.BomHelpers do
  @moduledoc false

  import ForgeWeb.ProjectLive.Components.Formatting, only: [money: 2]

  alias Forge.Projects.BomItem

  @spec bom_status_classes(BomItem.status()) :: String.t()
  def bom_status_classes(:needed),
    do:
      "bg-violet-50 text-violet-700 hover:bg-violet-100 dark:bg-violet-900/30 dark:text-violet-300"

  def bom_status_classes(:ordered),
    do: "bg-amber-50 text-amber-700 hover:bg-amber-100 dark:bg-amber-900/30 dark:text-amber-300"

  def bom_status_classes(:received),
    do:
      "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-900/30 dark:text-emerald-300"

  @spec bom_status_dot(BomItem.status()) :: String.t()
  def bom_status_dot(:needed), do: "bg-violet-500"
  def bom_status_dot(:ordered), do: "bg-amber-500"
  def bom_status_dot(:received), do: "bg-emerald-500"

  @spec item_total(BomItem.t()) :: Decimal.t()
  def item_total(%BomItem{} = item) do
    price = item.unit_price || Decimal.new(0)
    Decimal.mult(price, Decimal.new(item.quantity))
  end

  @spec budget_label(non_neg_integer(), Decimal.t(), String.t()) :: String.t()
  def budget_label(count, total, currency \\ "SEK") do
    "#{count} #{if count == 1, do: "item", else: "items"} · #{money(total, currency)} total"
  end
end
