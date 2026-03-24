defmodule Forge.Projects.Calculations.BomItemTotalPrice do
  @moduledoc """
  Calculates the total line price for a BOM item: `unit_price * quantity`.
  Returns `nil` if `unit_price` is nil.
  """
  use Ash.Resource.Calculation

  @impl Ash.Resource.Calculation
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      case record.unit_price do
        nil -> nil
        price -> Decimal.mult(price, Decimal.new(record.quantity))
      end
    end)
  end

  @impl Ash.Resource.Calculation
  def load(_query, _opts, _context), do: [:unit_price, :quantity]
end
