import Ecto.Query

alias Forge.Repo
alias Forge.Projects
alias Forge.Projects.{Project, Task, BomItem, JournalEntry}

existing_project_names =
  Repo.all(from(p in Project, select: p.name))
  |> MapSet.new()

ensure_project = fn attrs ->
  name = Map.fetch!(attrs, :name)

  if MapSet.member?(existing_project_names, name) do
    Repo.one!(from(p in Project, where: p.name == ^name))
  else
    {:ok, project} = Projects.create_project(attrs)
    project
  end
end

fridans =
  ensure_project.(%{
    name: "FRIDANS motorisering",
    status: "active",
    color: "emerald",
    description:
      "Motoriserad rullgardin med fokus på robust mekanik, enkel service och tydliga nästa steg.",
    tech_stack: "ESPHome · Home Assistant · 3D print",
    notes:
      "Mål: lätt att komma tillbaka efter en paus. Skriv alltid nästa konkreta steg som en task."
  })

starter =
  ensure_project.(%{
    name: "3D-print jig (idé)",
    status: "idea",
    color: "violet",
    description: "En liten idé som hålls varm utan att stjäla fokus.",
    notes: "När det finns en 30-min lucka: skissa mått och toleranser."
  })

existing_task_titles =
  Repo.all(from(t in Task, where: t.project_id == ^fridans.id, select: t.title))
  |> MapSet.new()

ensure_task = fn project, attrs ->
  title = Map.fetch!(attrs, :title)

  if MapSet.member?(existing_task_titles, title) do
    :ok
  else
    _ = Projects.create_task(Map.merge(attrs, %{project_id: project.id}))
  end
end

ensure_task.(fridans, %{title: "Designa motor-adapter", status: "in_progress", priority: "high"})

ensure_task.(fridans, %{title: "Verifiera moment & backdrive", status: "todo", priority: "medium"})

ensure_task.(fridans, %{title: "Beställa kablage", status: "blocked", priority: "medium"})
ensure_task.(fridans, %{title: "Sätta upp test-rigg", status: "done", priority: "low"})

existing_bom_names =
  Repo.all(from(b in BomItem, where: b.project_id == ^fridans.id, select: b.name))
  |> MapSet.new()

ensure_bom = fn project, attrs ->
  name = Map.fetch!(attrs, :name)

  if MapSet.member?(existing_bom_names, name) do
    :ok
  else
    _ = Projects.create_bom_item(Map.merge(attrs, %{project_id: project.id}))
  end
end

ensure_bom.(fridans, %{
  name: "N20 wormgear motor",
  quantity: 1,
  status: "received",
  unit_price: Decimal.new("79")
})

ensure_bom.(fridans, %{
  name: "DRV8833",
  quantity: 2,
  status: "ordered",
  unit_price: Decimal.new("25")
})

ensure_bom.(fridans, %{
  name: "PETG (filament)",
  quantity: 1,
  status: "needed",
  unit_price: Decimal.new("299")
})

existing_journal_titles =
  Repo.all(from(j in JournalEntry, where: j.project_id == ^fridans.id, select: j.title))
  |> MapSet.new()

ensure_journal = fn project, attrs ->
  title = Map.get(attrs, :title)

  key = title || "__untitled__"

  if MapSet.member?(existing_journal_titles, key) do
    :ok
  else
    _ = Projects.create_journal_entry(Map.merge(attrs, %{project_id: project.id}))
  end
end

ensure_journal.(fridans, %{title: "Första noteringen", body: "Byt fokus: ett nästa steg i taget."})

ensure_journal.(fridans, %{
  title: "Status",
  body: "Adapter-design börjar ta form. Behöver verifiera toleranser."
})

_ = starter
