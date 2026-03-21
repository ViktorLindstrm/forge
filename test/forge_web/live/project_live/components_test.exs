defmodule ForgeWeb.ProjectLive.ComponentsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ForgeWeb.ProjectLive.Components

  @colors [:blue, :violet, :emerald, :amber, :rose, :orange, :sky]
  @statuses [:idea, :active, :paused, :done]
  @task_statuses [:todo, :in_progress, :done, :blocked]
  @priorities [:low, :medium, :high]
  @bom_statuses [:needed, :ordered, :received]

  defp color_generator, do: one_of(Enum.map(@colors, &constant/1))
  defp status_generator, do: one_of(Enum.map(@statuses, &constant/1))

  # ── color_bg/1 ────────────────────────────────────────────────────────────

  describe "color_bg/1" do
    property "returns a non-empty CSS string for every defined color" do
      check all(color <- color_generator()) do
        result = Components.color_bg(color)
        assert is_binary(result)
        assert String.contains?(result, "bg-")
      end
    end

    test "returns distinct CSS strings for each color" do
      results = Enum.map(@colors, &Components.color_bg/1)
      assert length(Enum.uniq(results)) == length(@colors)
    end

    test "returns fallback gray gradient for unknown color" do
      result = Components.color_bg(:unknown)
      assert result == "bg-gradient-to-r from-gray-300 to-gray-400"
    end

    test "returns gradient strings using from-/to- Tailwind classes" do
      for color <- @colors do
        result = Components.color_bg(color)
        assert String.starts_with?(result, "bg-gradient-to-r from-")
      end
    end
  end

  # ── url_display/1 ─────────────────────────────────────────────────────────

  describe "url_display/1" do
    property "strips http:// prefix" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        url = "http://#{domain}.test"
        result = Components.url_display(url)
        refute String.starts_with?(result, "http://")
        assert String.contains?(result, domain)
      end
    end

    property "strips https:// prefix" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        url = "https://#{domain}.test"
        result = Components.url_display(url)
        refute String.starts_with?(result, "https://")
        assert String.contains?(result, domain)
      end
    end

    property "strips trailing slash" do
      check all(domain <- string(:alphanumeric, min_length: 1, max_length: 30)) do
        url = "https://#{domain}.test/"
        result = Components.url_display(url)
        refute String.ends_with?(result, "/")
      end
    end

    test "leaves URLs without trailing slash unchanged (after prefix strip)" do
      assert Components.url_display("https://example.com") == "example.com"
    end

    test "handles URL with path segments" do
      assert Components.url_display("https://github.com/user/repo") == "github.com/user/repo"
    end
  end

  # ── bom_params/0 ──────────────────────────────────────────────────────────

  describe "bom_params/0" do
    test "returns map with expected default keys" do
      params = Components.bom_params()
      assert is_map(params)
      assert Map.has_key?(params, "name")
      assert Map.has_key?(params, "quantity")
      assert Map.has_key?(params, "unit_price")
    end

    test "name defaults to empty string" do
      assert Components.bom_params()["name"] == ""
    end

    test "quantity defaults to 1" do
      assert Components.bom_params()["quantity"] == 1
    end

    test "unit_price defaults to empty string" do
      assert Components.bom_params()["unit_price"] == ""
    end

    test "Components.bom_params/0 and Bom.bom_params/0 return identical values" do
      assert Components.bom_params() == ForgeWeb.ProjectLive.Bom.bom_params()
    end
  end

  # ── status badge colour consistency ────────────────────────────────────────

  describe "status_badge color consistency" do
    property "status_badge renders for all project statuses without raising" do
      check all(status <- status_generator()) do
        assigns = %{status: status, __changed__: nil}
        rendered = Components.status_badge(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end
  end

  # ── pill renders for task statuses and priorities ──────────────────────────

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
  end

  # ── bom_status consistency ─────────────────────────────────────────────────

  describe "bom status visual helpers" do
    test "all BOM statuses render via pill without raising" do
      for status <- @bom_statuses do
        assigns = %{kind: "status", value: status, __changed__: nil}
        rendered = Components.pill(assigns)
        assert is_struct(rendered, Phoenix.LiveView.Rendered)
      end
    end
  end
end
