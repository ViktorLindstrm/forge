defmodule ForgeWeb.ProjectLive.BomTest do
  use Forge.DataCase

  alias ForgeWeb.ProjectLive.Bom

  describe "bom_form/0" do
    test "returns a Phoenix.HTML.Form backed by AshPhoenix.Form for :create" do
      form = Bom.bom_form()
      assert %Phoenix.HTML.Form{} = form
      assert %AshPhoenix.Form{} = form.source
      assert form.source.resource == Forge.Projects.BomItem
      assert form.source.action == :create
      assert form.name == "bom"
    end
  end
end
