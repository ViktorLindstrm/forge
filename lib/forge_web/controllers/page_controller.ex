defmodule ForgeWeb.PageController do
  use ForgeWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/projects")
  end
end
