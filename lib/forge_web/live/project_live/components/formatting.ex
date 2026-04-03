defmodule ForgeWeb.ProjectLive.Components.Formatting do
  @moduledoc false

  @currency_symbols %{
    "SEK" => "kr",
    "NOK" => "kr",
    "DKK" => "kr",
    "EUR" => "€",
    "USD" => "$",
    "GBP" => "£",
    "CHF" => "CHF",
    "JPY" => "¥",
    "CAD" => "CA$",
    "AUD" => "A$"
  }

  @prefix_currencies ["EUR", "USD", "GBP", "JPY", "CAD", "AUD"]

  @spec url_display(String.t()) :: String.t()
  def url_display(url) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/\/$/, "")
  end

  @spec money(Decimal.t()) :: String.t()
  def money(%Decimal{} = amount) do
    money(amount, "SEK")
  end

  @spec money(Decimal.t(), String.t()) :: String.t()
  def money(%Decimal{} = amount, currency) do
    rounded = Decimal.round(amount, 2)

    formatted =
      if Decimal.equal?(rounded, Decimal.round(rounded, 0)) do
        rounded |> Decimal.round(0) |> Decimal.to_string(:normal)
      else
        Decimal.to_string(rounded, :normal)
      end

    symbol = Map.get(@currency_symbols, currency, currency)

    if currency in @prefix_currencies do
      "#{symbol}#{formatted}"
    else
      "#{formatted} #{symbol}"
    end
  end

  @spec currency_symbol(String.t()) :: String.t()
  def currency_symbol(currency), do: Map.get(@currency_symbols, currency, currency)

  @spec currency_prefix?(String.t()) :: boolean()
  def currency_prefix?(currency), do: currency in @prefix_currencies
end
