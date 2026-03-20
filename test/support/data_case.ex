defmodule Forge.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnitProperties
      import StreamData
      alias Forge.Repo

      setup tags do
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Forge.Repo, shared: not tags[:async])
        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        :ok
      end
    end
  end
end
