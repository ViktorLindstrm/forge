defmodule ForgeWeb.PageControllerTest do
  use ForgeWeb.ConnCase, async: true
  use ExUnitProperties

  property "GET / redirects to /projects", %{conn: conn} do
    check all(_ <- constant(:ok)) do
      conn = get(conn, ~p"/")
      assert redirected_to(conn, 302) == ~p"/projects"
    end
  end
end
