defmodule ForgeWeb.PageControllerTest do
  use ForgeWeb.ConnCase

  test "GET / redirects to projects", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) == ~p"/projects"
  end
end
