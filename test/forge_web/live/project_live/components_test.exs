defmodule ForgeWeb.ProjectLive.ComponentsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ForgeWeb.ProjectLive.Components
  alias ForgeWeb.ProjectLive.Components.Formatting

  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]
  @statuses [:idea, :active, :paused, :done]
  @task_statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]
  @bom_statuses [:needed, :ordered, :received]

  @suffix_currencies ["SEK", "NOK", "DKK", "CHF"]
  @prefix_currencies ["EUR", "USD", "GBP", "JPY", "CAD", "AUD"]
  @all_currencies @suffix_currencies ++ @prefix_currencies

  defp color_generator, do: one_of(Enum.map(@colors, &constant/1))
  defp status_generator, do: one_of(Enum.map(@statuses, &constant/1))

  defp amount_generator do
    map(
      {non_negative_integer(), integer(0..99)},
      fn {whole, frac} ->
        Decimal.new("#{whole}.#{String.pad_leading(to_string(frac), 2, "0")}")
      end
    )
  end

  defp formatted_number_str(amount) do
    rounded = Decimal.round(amount, 2)

    if Decimal.equal?(rounded, Decimal.round(rounded, 0)) do
      rounded |> Decimal.round(0) |> Decimal.to_string(:normal)
    else
      Decimal.to_string(rounded, :normal)
    end
  end

  describe "Formatting.currency_prefix?/1" do
    property "suffix currencies return false" do
      check all(currency <- one_of(Enum.map(@suffix_currencies, &constant/1))) do
        refute Formatting.currency_prefix?(currency),
               "Expected #{currency} to be a suffix currency"
      end
    end

    property "prefix currencies return true" do
      check all(currency <- one_of(Enum.map(@prefix_currencies, &constant/1))) do
        assert Formatting.currency_prefix?(currency),
               "Expected #{currency} to be a prefix currency"
      end
    end
  end

  describe "Formatting.money/2" do
    property "suffix currencies: symbol appears after the number" do
      check all(
              currency <- one_of(Enum.map(@suffix_currencies, &constant/1)),
              amount <- amount_generator()
            ) do
        result = Formatting.money(amount, currency)
        symbol = Formatting.currency_symbol(currency)
        number_str = formatted_number_str(amount)

        assert String.ends_with?(result, symbol),
               "#{currency}: expected '#{result}' to end with '#{symbol}'"

        assert String.contains?(result, number_str),
               "#{currency}: expected '#{result}' to contain number '#{number_str}'"

        refute String.starts_with?(result, symbol),
               "#{currency}: symbol should not be a prefix, got '#{result}'"
      end
    end

    property "prefix currencies: symbol appears before the number" do
      check all(
              currency <- one_of(Enum.map(@prefix_currencies, &constant/1)),
              amount <- amount_generator()
            ) do
        result = Formatting.money(amount, currency)
        symbol = Formatting.currency_symbol(currency)
        number_str = formatted_number_str(amount)

        assert String.starts_with?(result, symbol),
               "#{currency}: expected '#{result}' to start with '#{symbol}'"

        assert String.ends_with?(result, number_str),
               "#{currency}: expected '#{result}' to end with number '#{number_str}'"
      end
    end

    property "USD formats as dollar-sign-prefixed number" do
      check all(amount <- amount_generator()) do
        result = Formatting.money(amount, "USD")

        assert String.starts_with?(result, "$"),
               "USD: expected dollar prefix, got '#{result}'"
      end
    end

    property "SEK formats as number followed by kr" do
      check all(amount <- amount_generator()) do
        result = Formatting.money(amount, "SEK")

        assert String.ends_with?(result, "kr"),
               "SEK: expected 'kr' suffix, got '#{result}'"
      end
    end

    property "all currencies produce non-empty strings containing the amount" do
      check all(
              currency <- one_of(Enum.map(@all_currencies, &constant/1)),
              amount <- amount_generator()
            ) do
        result = Formatting.money(amount, currency)

        assert is_binary(result) and result != "",
               "#{currency}: money/2 returned empty string"

        number_str = formatted_number_str(amount)

        assert String.contains?(result, number_str),
               "#{currency}: expected result to contain '#{number_str}', got '#{result}'"
      end
    end

    property "money/1 defaults to SEK suffix format" do
      check all(amount <- amount_generator()) do
        result_default = Formatting.money(amount)
        result_sek = Formatting.money(amount, "SEK")

        assert result_default == result_sek,
               "money/1 should equal money/2 with SEK"
      end
    end

    property "whole-number amounts have no decimal point" do
      check all(
              whole <- non_negative_integer(),
              currency <- one_of(Enum.map(@all_currencies, &constant/1))
            ) do
        amount = Decimal.new(whole)
        result = Formatting.money(amount, currency)

        refute String.contains?(result, "."),
               "#{currency}: whole amount #{whole} should not contain '.', got '#{result}'"
      end
    end

    property "amounts with cents include decimal point" do
      check all(
              whole <- non_negative_integer(),
              frac <- integer(1..99),
              currency <- one_of(Enum.map(@all_currencies, &constant/1))
            ) do
        amount = Decimal.new("#{whole}.#{String.pad_leading(to_string(frac), 2, "0")}")
        result = Formatting.money(amount, currency)

        assert String.contains?(result, "."),
               "#{currency}: amount with cents should contain '.', got '#{result}'"
      end
    end
  end

  describe "color_bg/1" do
    property "returns a non-empty CSS string for every defined color" do
      check all(color <- color_generator()) do
        result = Components.color_bg(color)
        assert is_binary(result)
        assert String.contains?(result, "bg-")
      end
    end

    property "returns distinct CSS strings for all defined colors" do
      check all(_ <- constant(:ok)) do
        results = Enum.map(@colors, &Components.color_bg/1)
        assert length(Enum.uniq(results)) == length(@colors)
      end
    end

    property "returns fallback gray gradient for any unknown color atom" do
      check all(
              color <-
                atom(:alphanumeric)
                |> StreamData.filter(&(&1 not in @colors))
            ) do
        result = Components.color_bg(color)
        assert result == "bg-gradient-to-r from-gray-200 via-gray-400 to-gray-500"
      end
    end

    property "returns gradient strings with from-/to- Tailwind classes for all defined colors" do
      check all(color <- color_generator()) do
        result = Components.color_bg(color)
        assert String.starts_with?(result, "bg-gradient-to-r from-")
      end
    end
  end

  describe "url_display/1" do
    property "strips http scheme prefix" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        scheme = "http"
        url = scheme <> "://" <> domain <> ".test"
        result = Components.url_display(url)
        refute String.starts_with?(result, scheme <> "://")
        assert String.contains?(result, domain)
      end
    end

    property "strips https scheme prefix" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        scheme = "https"
        url = scheme <> "://" <> domain <> ".test"
        result = Components.url_display(url)
        refute String.starts_with?(result, scheme <> "://")
        assert String.contains?(result, domain)
      end
    end

    property "strips trailing slash" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        url = "https" <> "://" <> domain <> ".test/"
        result = Components.url_display(url)
        refute String.ends_with?(result, "/")
      end
    end

    property "leaves URLs without trailing slash unchanged after prefix strip" do
      check all(_ <- constant(:ok)) do
        assert Components.url_display("https" <> "://example.com") == "example.com"
      end
    end

    property "handles URLs with path segments" do
      check all(_ <- constant(:ok)) do
        assert Components.url_display("https" <> "://github.com/user/repo") ==
                 "github.com/user/repo"
      end
    end
  end

  describe "bom_form/0" do
    property "returns a Phoenix.HTML.Form backed by AshPhoenix.Form with name 'bom'" do
      check all(_ <- constant(:ok)) do
        form = Components.bom_form()
        assert %Phoenix.HTML.Form{} = form
        assert %AshPhoenix.Form{} = form.source
        assert form.name == "bom"
      end
    end
  end

  describe "status_badge color consistency" do
    property "status_badge renders for all project statuses without raising" do
      check all(status <- status_generator()) do
        assigns = %{status: status, __changed__: nil}
        rendered = Components.status_badge(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end
  end

  describe "pill/1" do
    property "pill renders for all task statuses" do
      check all(status <- one_of(Enum.map(@task_statuses, &constant/1))) do
        assigns = %{kind: "status", value: status, __changed__: nil}
        rendered = Components.pill(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end

    property "pill renders for all priority values" do
      check all(priority <- one_of(Enum.map(@priorities, &constant/1))) do
        assigns = %{kind: "priority", value: priority, __changed__: nil}
        rendered = Components.pill(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end

    property "pill renders for all BOM statuses without raising" do
      check all(status <- one_of(Enum.map(@bom_statuses, &constant/1))) do
        assigns = %{kind: "status", value: status, __changed__: nil}
        rendered = Components.pill(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end
  end
end
