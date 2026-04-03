defmodule ForgeWeb.Plugs.SafeCheckRepoStatus do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, opts) do
    try do
      Phoenix.Ecto.CheckRepoStatus.call(conn, opts)
    rescue
      _ -> conn
    end
  end
end
