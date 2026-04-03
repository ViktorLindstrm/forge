defmodule ForgeWeb.Markdown do
  @moduledoc """
  Renders Markdown to sanitized HTML for safe display in templates.
  """

  @spec render(String.t() | nil) :: Phoenix.HTML.safe()
  def render(nil), do: Phoenix.HTML.raw("")

  def render(text) when is_binary(text) do
    {:ok, html, _} = Earmark.as_html(text, compact_output: true, breaks: true)
    safe = HtmlSanitizeEx.markdown_html(html)
    Phoenix.HTML.raw(safe)
  end
end
