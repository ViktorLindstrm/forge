defmodule ForgeWeb.ErrorHTMLTest do
  use ForgeWeb.ConnCase, async: true
  use ExUnitProperties

  import Phoenix.Template, only: [render_to_string: 4]

  property "renders 404.html as Not Found" do
    check all(_ <- constant(:ok)) do
      assert render_to_string(ForgeWeb.ErrorHTML, "404", "html", []) == "Not Found"
    end
  end

  property "renders 500.html as Internal Server Error" do
    check all(_ <- constant(:ok)) do
      assert render_to_string(ForgeWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
    end
  end
end
