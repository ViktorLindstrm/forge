defmodule ForgeWeb.ErrorJSONTest do
  use ForgeWeb.ConnCase, async: true
  use ExUnitProperties

  property "renders 404 as not found JSON" do
    check all(_ <- constant(:ok)) do
      assert ForgeWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
    end
  end

  property "renders 500 as internal server error JSON" do
    check all(_ <- constant(:ok)) do
      assert ForgeWeb.ErrorJSON.render("500.json", %{}) ==
               %{errors: %{detail: "Internal Server Error"}}
    end
  end
end
