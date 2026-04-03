defmodule ForgeWeb.MarkdownTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ForgeWeb.Markdown

  describe "render/1" do
    property "returns empty safe HTML for nil input" do
      check all(_ <- constant(nil)) do
        result = Markdown.render(nil)
        assert Phoenix.HTML.safe_to_string(result) == ""
      end
    end

    property "renders bold markdown with **text** syntax" do
      check all(word <- string(:alphanumeric, min_length: 1, max_length: 40)) do
        result = Markdown.render("**#{word}**")
        html = Phoenix.HTML.safe_to_string(result)
        assert html =~ "<strong>#{word}</strong>"
      end
    end

    property "renders inline code with backtick syntax" do
      check all(word <- string(:alphanumeric, min_length: 1, max_length: 40)) do
        result = Markdown.render("`#{word}`")
        html = Phoenix.HTML.safe_to_string(result)
        assert html =~ "<code"
        assert html =~ ">#{word}<"
      end
    end

    property "renders italic markdown with _text_ syntax" do
      check all(word <- string(:alphanumeric, min_length: 1, max_length: 40)) do
        result = Markdown.render("_#{word}_")
        html = Phoenix.HTML.safe_to_string(result)
        assert html =~ "<em>#{word}</em>"
      end
    end

    property "strips script tags for XSS prevention" do
      check all(payload <- string(:alphanumeric, min_length: 0, max_length: 50)) do
        result = Markdown.render("<script>#{payload}</script>")
        html = Phoenix.HTML.safe_to_string(result)
        refute html =~ "<script>"
      end
    end

    property "strips javascript: hrefs for XSS prevention" do
      check all(label <- string(:alphanumeric, min_length: 1, max_length: 20)) do
        result = Markdown.render("[#{label}](javascript:alert(1))")
        html = Phoenix.HTML.safe_to_string(result)
        refute html =~ "javascript:"
      end
    end

    property "always returns a Phoenix.HTML.safe value for any printable single-line string" do
      check all(
              text <-
                string(:printable, min_length: 0, max_length: 200)
                |> StreamData.filter(fn s -> not String.contains?(s, ["\n", "\r"]) end)
            ) do
        result = Markdown.render(text)
        assert match?({:safe, _}, result)
      end
    end

    property "never outputs script tags regardless of input" do
      check all(
              text <-
                string(:printable, min_length: 0, max_length: 200)
            ) do
        html = Markdown.render(text) |> Phoenix.HTML.safe_to_string()
        refute html =~ "<script"
      end
    end
  end
end
