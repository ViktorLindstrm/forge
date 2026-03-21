defmodule ForgeWeb.ProjectLive.Components.Formatting do
  @moduledoc false

  @type url :: String.t()

  @spec url_display(url()) :: String.t()
  def url_display(url) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/\/$/, "")
  end

  @spec money(Decimal.t()) :: String.t()
  def money(%Decimal{} = amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
  end
end
