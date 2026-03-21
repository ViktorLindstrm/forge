defmodule ForgeWeb.ProjectLive.Components.BomHelpers do
  @moduledoc false

  import ForgeWeb.ProjectLive.Components.Formatting, only: [money: 1]

  @type status :: :needed | :ordered | :received | atom()

  @type bom_item_like :: %{
          required(:quantity) => pos_integer(),
          optional(:unit_price) => Decimal.t() | nil
        }

  @spec bom_status_classes(status()) :: String.t()
  def bom_status_classes(:needed),
    do:
      "bg-violet-50 text-violet-700 hover:bg-violet-100 dark:bg-violet-900/30 dark:text-violet-300"

  def bom_status_classes(:ordered),
    do: "bg-amber-50 text-amber-700 hover:bg-amber-100 dark:bg-amber-900/30 dark:text-amber-300"

  def bom_status_classes(:received),
    do:
      "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-900/30 dark:text-emerald-300"

  def bom_status_classes(_),
    do: "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"

  @spec bom_status_dot(status()) :: String.t()
  def bom_status_dot(:needed), do: "bg-violet-500"
  def bom_status_dot(:ordered), do: "bg-amber-500"
  def bom_status_dot(:received), do: "bg-emerald-500"
  def bom_status_dot(_), do: "bg-gray-400"

  @spec item_total(bom_item_like()) :: Decimal.t()
  def item_total(item) do
    price = Map.get(item, :unit_price) || Decimal.new(0)
    Decimal.mult(price, Decimal.new(Map.fetch!(item, :quantity)))
  end

  @type bom_budget_like :: %{
          required(:items) => list(term()),
          required(:total) => Decimal.t(),
          required(:spent) => Decimal.t()
        }

  @spec budget_label(bom_budget_like()) :: String.t()
  def budget_label(%{items: items, total: total, spent: spent}) do
    remaining = Decimal.sub(total, spent)
    "#{length(items)} items · #{money(spent)}/#{money(total)} spent · #{money(remaining)} left"
  end
end
