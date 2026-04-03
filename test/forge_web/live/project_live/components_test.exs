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

    property "leaves URLs without trailing slash unchanged after prefix strip" do
      check all(_ <- constant(:ok)) do
        assert Components.url_display("https://example.com") == "example.com"
      end
    end

    property "handles URLs with path segments" do
      check all(_ <- constant(:ok)) do
        assert Components.url_display("https://github.com/user/repo") == "github.com/user/repo"
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
