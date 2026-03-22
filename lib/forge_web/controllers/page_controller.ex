defmodule ForgeWeb.PageController do
  use ForgeWeb, :controller

  @spec home(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def home(conn, _params) do
    redirect(conn, to: "/projects")
  end
end
