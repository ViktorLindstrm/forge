alias Forge.{Category, Project, BomItem, JournalEntry, Task}

# ── Kategorier (idempotent) ───────────────────────────────────────────────────

[
  %{name: "3D-printing",   slug: "3d_printing", icon: "🖨️", color: "#993C1D"},
  %{name: "Programmering", slug: "programming", icon: "💻", color: "#534AB7"},
  %{name: "Elektronik",    slug: "electronics", icon: "⚡", color: "#0F6E56"},
  %{name: "Hemma",         slug: "home",        icon: "🏠", color: "#854F0B"},
]
|> Enum.each(fn attrs ->
  Category
  |> Ash.Changeset.for_create(:create, attrs)
  |> Ash.create!(upsert?: true, upsert_identity: :unique_slug)
end)

IO.puts("✓ Kategorier seedade")

# ── Projekt (bara om databasen är tom) ───────────────────────────────────────

elec = Ash.get!(Forge.Category, [slug: "electronics"], domain: Forge.Domain)

project =
  case Ash.read(Forge.Project, domain: Forge.Domain) do
    {:ok, [existing | _]} ->
      IO.puts("✓ Projekt finns redan, skippar")
      existing

    {:ok, []} ->
      {:ok, p} =
        Project.create(%{
          name: "FRIDANS-motorisering",
          description: """
          Motoriserad IKEA FRIDANS rullgardin med N20 wormgear-motor, DRV8833 H-bridge och \
          XIAO ESP32-C6. Styrs via ESPHome och Home Assistant. Wormgear valdes för att \
          undvika backdrive — gardinen håller position utan ström. Motor-adapter till \
          blindtuben printas i PETG.
          """,
          status: :active,
          category_id: elec.id
        })
      p
  end

# ── BOM ───────────────────────────────────────────────────────────────────────

if Ash.read!(Forge.BomItem, domain: Forge.Domain) == [] do
  [
    %{name: "XIAO ESP32-C6",      quantity: 1, supplier: "Seeed Studio", unit_price: Decimal.new("89"),  currency: "SEK", status: :received, sort_order: 1},
    %{name: "DRV8833 H-bridge",   quantity: 1, supplier: "AliExpress",   unit_price: Decimal.new("35"),  currency: "SEK", status: :received, sort_order: 2},
    %{name: "N20 Wormgear 6V",    quantity: 1, supplier: "AliExpress",   unit_price: Decimal.new("78"),  currency: "SEK", status: :received, sort_order: 3},
    %{name: "LiPo 3,7V 400mAh",   quantity: 1, supplier: "AliExpress",   unit_price: Decimal.new("45"),  currency: "SEK", status: :ordered,  sort_order: 4},
    %{name: "Motor-adapter PETG", quantity: 1, supplier: "Egenprint",    unit_price: Decimal.new("0"),   currency: "SEK", status: :needed,   sort_order: 5},
  ]
  |> Enum.each(fn attrs ->
    BomItem.create!(Map.put(attrs, :project_id, project.id))
  end)
  IO.puts("✓ BOM seedat")
end

# ── Journal-poster ────────────────────────────────────────────────────────────

if Ash.read!(Forge.JournalEntry, domain: Forge.Domain) == [] do
  [
    %{
      title: "Projekt skapat",
      body: "Initial idé dokumenterad. Tre FRIDANS-gardiner i vardagsrum — manuell hantering på morgonen är oacceptabelt.",
    },
    %{
      title: "Komponent-research klar",
      body: """
      Valde N20 wormgear framför vanlig N20 — ingen backdrive gör att gardinen håller \
      position utan ström. DRV8833 föredraget framför L298N pga storlek och lägre \
      spänningsfall. Kan driva 2 motorer vilket lämnar expansion öppen.

      Beställt från AliExpress, 2–3 veckors leveranstid.
      """,
    },
    %{
      title: "Motor-adapter printad, första rörelstest",
      body: """
      Printade fästet i PETG — passning mot tuben lite tight, ska skala ned X/Y 0.3% \
      i nästa print. DRV8833 kopplad och testad med enkel PWM. Rörelsen är smidig men \
      rampning i ESPHome behöver tunas.

      Noterade att `slow_pwm`-plattformen introducerar jitter vid låga hastigheter — \
      kör vidare med `ledc` på nästa test.

      :::bom
      - [x] XIAO ESP32-C6 ×1 | Seeed Studio | 89 SEK
      - [x] DRV8833 H-bridge ×1 | AliExpress | 35 SEK
      - [x] N20 Wormgear 6V ×1 | AliExpress | 78 SEK
      - [ ] LiPo 3,7V 400mAh ×1 | AliExpress | 45 SEK
      - [ ] Motor-adapter PETG ×1 | Egenprint | 0 SEK
      :::
      """,
    },
  ]
  |> Enum.each(fn attrs ->
    JournalEntry.create!(Map.put(attrs, :project_id, project.id))
  end)
  IO.puts("✓ Journal seedat")
end

# ── Tasks ─────────────────────────────────────────────────────────────────────

if Ash.read!(Forge.Task, domain: Forge.Domain) == [] do
  today = Date.utc_today()

  [
    %{title: "Designa motor-adapter för blindtub", status: :in_progress, priority: :high,   due_date: today,             sort_order: 1},
    %{title: "Beställa LiPo 3,7V 400mAh",         status: :todo,        priority: :medium,  due_date: Date.add(today, -2), sort_order: 2},
    %{title: "Tuna ESPHome-rampning med ledc",     status: :blocked,     priority: :medium,  due_date: nil,               sort_order: 3},
    %{title: "Koppla DRV8833 och testa PWM",       status: :done,        priority: :low,     due_date: nil,               sort_order: 4},
    %{title: "Verifiera wormgear backdrive-frihet", status: :done,       priority: :low,     due_date: nil,               sort_order: 5},
  ]
  |> Enum.each(fn attrs ->
    Task.create!(Map.put(attrs, :project_id, project.id))
  end)
  IO.puts("✓ Tasks seedade")
end
