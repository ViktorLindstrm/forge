defmodule ForgeWeb.CoreComponents do
  use PetalComponents

  @moduledoc """
  Provides core UI components.

  Built on top of PetalComponents with custom additions for flash messages,
  headers, and data lists.
  """
  use Phoenix.Component
  use Gettext, backend: ForgeWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-4 right-4 z-50 w-80 sm:w-96 rounded-lg shadow-lg p-4 flex gap-3 items-start",
        @kind == :info && "bg-blue-50 text-blue-800 border border-blue-200",
        @kind == :error && "bg-red-50 text-red-800 border border-red-200"
      ]}
      {@rest}
    >
      <.icon
        :if={@kind == :info}
        name="hero-information-circle"
        class="size-5 shrink-0 text-blue-500"
      />
      <.icon
        :if={@kind == :error}
        name="hero-exclamation-circle"
        class="size-5 shrink-0 text-red-500"
      />
      <div class="flex-1 min-w-0">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p class="text-sm">{msg}</p>
      </div>
      <button type="button" class="group cursor-pointer shrink-0" aria-label={gettext("close")}>
        <.icon name="hero-x-mark" class="size-4 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-gray-500">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="divide-y divide-gray-100">
      <div :for={item <- @item} class="px-4 py-3 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
        <dt class="text-sm font-medium text-gray-900">{item.title}</dt>
        <dd class="mt-1 text-sm text-gray-700 sm:col-span-2 sm:mt-0">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  ## JS Commands

  @spec show(Phoenix.LiveView.JS.t(), String.t()) :: Phoenix.LiveView.JS.t()
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @spec hide(Phoenix.LiveView.JS.t(), String.t()) :: Phoenix.LiveView.JS.t()
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({String.t(), keyword()}) :: String.t()
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ForgeWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ForgeWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  @spec translate_errors(keyword(), atom()) :: [String.t()]
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
