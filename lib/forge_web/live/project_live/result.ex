defmodule ForgeWeb.ProjectLive.Result do
  @type assign_key :: atom()

  @type stream_name :: atom()

  @type stream_reset(item) :: {:reset, stream_name(), [item]}
  @type stream_op(item) :: stream_reset(item)

  @type stream_delete(item) :: {stream_name(), item}

  @type ok(item) ::
          {:ok,
           %{
             optional(:assigns) => keyword(),
             optional(:stream) => stream_op(item),
             optional(:stream_delete) => stream_delete(item)
           }}

  @type error_changeset :: {:error, {:changeset, Ecto.Changeset.t()}}
end
