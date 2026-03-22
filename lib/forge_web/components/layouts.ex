defmodule ForgeWeb.Layouts do
  @moduledoc """
  Application layout components.
  """
  use ForgeWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  @spec app(map()) :: Phoenix.LiveView.Rendered.t()
  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
      <nav class="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 sticky top-0 z-40">
        <div class="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-14">
            <a href="/projects" class="flex items-center gap-2.5 group">
              <div class="size-7 rounded-lg bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center shadow-sm">
                <.icon name="hero-bolt-micro" class="size-4 text-white" />
              </div>
              <span class="font-bold text-gray-900 dark:text-white text-base tracking-tight group-hover:text-violet-600 dark:group-hover:text-violet-400 transition-colors">
                Forge
              </span>
            </a>

            <div class="flex items-center gap-2">
              <.theme_toggle />
            </div>
          </div>
        </div>
      </nav>

      <main class="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-8">
        {render_slot(@inner_block)}
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  @spec flash_group(map()) :: Phoenix.LiveView.Rendered.t()
  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="Connection lost"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @spec theme_toggle(map()) :: Phoenix.LiveView.Rendered.t()
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center bg-gray-100 dark:bg-gray-800 rounded-full p-0.5 gap-0.5">
      <button
        class="flex p-1.5 cursor-pointer rounded-full hover:bg-white dark:hover:bg-gray-700 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="System theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3.5 text-gray-500 dark:text-gray-400" />
      </button>
      <button
        class="flex p-1.5 cursor-pointer rounded-full hover:bg-white dark:hover:bg-gray-700 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        title="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-3.5 text-gray-500 dark:text-gray-400" />
      </button>
      <button
        class="flex p-1.5 cursor-pointer rounded-full hover:bg-white dark:hover:bg-gray-700 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-3.5 text-gray-500 dark:text-gray-400" />
      </button>
    </div>
    """
  end
end
