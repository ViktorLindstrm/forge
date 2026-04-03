defmodule ForgeWeb.ProjectLive.BomHandlers do
  @moduledoc """
  Handles all BOM-item `handle_event` clauses for `ForgeWeb.ProjectLive.Show`.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3]

  alias Forge.Projects
  alias ForgeWeb.ProjectLive.Bom

  @type socket :: Phoenix.LiveView.Socket.t()

  @spec toggle_bom_form(map(), socket()) :: {:noreply, socket()}
  def toggle_bom_form(_params, socket) do
    {:noreply, assign(socket, :bom_form_open?, !socket.assigns.bom_form_open?)}
  end

  @spec bom_create(map(), socket()) :: {:noreply, socket()}
  def bom_create(%{"bom" => params}, socket) do
    project_id = socket.assigns.project.id
    params = Map.put(params, "project_id", project_id)

    case AshPhoenix.Form.submit(socket.assigns.bom_form.source, params: params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> reload_bom()
         |> assign(:bom_form, Bom.bom_form())
         |> assign(:bom_form_open?, false)}

      {:error, form} ->
        {:noreply, assign(socket, :bom_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec bom_delete(map(), socket()) :: {:noreply, socket()}
  def bom_delete(%{"id" => id}, socket) do
    item = Projects.get_bom_item!(id)

    case Projects.delete_bom_item(item) do
      {:ok, _} -> {:noreply, reload_bom(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete BOM item.")}
    end
  end

  @spec bom_toggle(map(), socket()) :: {:noreply, socket()}
  def bom_toggle(%{"id" => id}, socket) do
    item = Projects.get_bom_item!(id)

    case Projects.toggle_bom_item_status(item) do
      {:ok, _item} -> {:noreply, reload_bom(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not update BOM item.")}
    end
  end

  @spec bom_edit_open(map(), socket()) :: {:noreply, socket()}
  def bom_edit_open(%{"id" => id}, socket) do
    item = Projects.get_bom_item!(id)
    form = Bom.bom_edit_form(item)

    {:noreply,
     socket
     |> assign(:editing_bom_id, item.id)
     |> assign(:bom_edit_form, form)
     |> assign(:bom_form_open?, false)}
  end

  @spec bom_edit_cancel(map(), socket()) :: {:noreply, socket()}
  def bom_edit_cancel(_params, socket) do
    {:noreply,
     socket
     |> assign(:editing_bom_id, nil)
     |> assign(:bom_edit_form, nil)}
  end

  @spec bom_edit_validate(map(), socket()) :: {:noreply, socket()}
  def bom_edit_validate(%{"bom_edit" => params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.bom_edit_form.source, params)
      |> Phoenix.Component.to_form()

    {:noreply, assign(socket, :bom_edit_form, form)}
  end

  @spec bom_edit_save(map(), socket()) :: {:noreply, socket()}
  def bom_edit_save(%{"bom_edit" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.bom_edit_form.source, params: params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> reload_bom()
         |> assign(:editing_bom_id, nil)
         |> assign(:bom_edit_form, nil)}

      {:error, form} ->
        {:noreply, assign(socket, :bom_edit_form, Phoenix.Component.to_form(form))}
    end
  end

  @spec reload_bom(socket()) :: socket()
  def reload_bom(socket) do
    project_id = socket.assigns.project.id
    project = Projects.get_project!(project_id)

    socket
    |> assign(:project, project)
    |> assign(:bom_budget, Projects.bom_budget(project_id))
  end
end
