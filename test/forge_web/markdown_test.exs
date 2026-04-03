defmodule ForgeWeb.MarkdownTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ForgeWeb.Markdown

  describe "render/1" do
    test "returns empty safe HTML for nil" do
      result = Markdown.render(nil)
      assert Phoenix.HTML.safe_to_string(result) == ""
    end

    test "renders bold markdown" do
      result = Markdown.render("**hello**")
      html = Phoenix.HTML.safe_to_string(result)
      assert html =~ "<strong>hello</strong>"
    end

    test "renders inline code" do
      result = Markdown.render("`code`")
      html = Phoenix.HTML.safe_to_string(result)
      assert html =~ "<code"
      assert html =~ ">code<"
    end

    test "renders italic markdown" do
      result = Markdown.render("_italic_")
      html = Phoenix.HTML.safe_to_string(result)
      assert html =~ "<em>italic</em>"
    end

    test "strips script tags for XSS prevention" do
      result = Markdown.render("<script>alert('xss')</script>")
      html = Phoenix.HTML.safe_to_string(result)
      refute html =~ "<script>"
    end

    test "strips javascript href for XSS prevention" do
      result = Markdown.render("[click](javascript:alert(1))")
      html = Phoenix.HTML.safe_to_string(result)
      refute html =~ "javascript:"
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
