import Ecto.Query

alias Forge.Repo
alias Forge.Projects
alias Forge.Projects.{Project, Task, BomItem, JournalEntry, ProjectGroup}

# ── Wipe ──────────────────────────────────────────────────────────────────
Repo.delete_all(JournalEntry)
Repo.delete_all(BomItem)
Repo.delete_all(from(t in Task, where: not is_nil(t.parent_task_id)))
Repo.delete_all(Task)
Repo.delete_all(Project)
Repo.delete_all(ProjectGroup)

# ── Groups ────────────────────────────────────────────────────────────────
{:ok, hw}   = Projects.create_project_group(%{name: "Hardware"})
{:ok, sw}   = Projects.create_project_group(%{name: "Software"})
{:ok, home} = Projects.create_project_group(%{name: "Home & Workshop"})
{:ok, moto} = Projects.create_project_group(%{name: "Motorsport"})

# ── Projects ──────────────────────────────────────────────────────────────

{:ok, blind} = Projects.create_project(%{
  name: "FRIDANS Motorization",
  status: :active, color: :emerald,
  description: "Motorized roller blind using an N20 worm-gear motor driven by ESPHome. Integrates with Home Assistant automations. Focus on silent operation and robust end-stop detection.",
  tech_stack: "ESPHome · Home Assistant · DRV8833 · 3D Print",
  url: "https://github.com/example/fridans-motor",
  notes: "Target: silent under 40 dB. Always write next concrete step as a task before closing session.",
  budget: Decimal.new("850"),
  project_group_id: hw.id
})

{:ok, weather} = Projects.create_project(%{
  name: "Garden Weather Station",
  status: :active, color: :sky,
  description: "Solar-powered outdoor node reporting temperature, humidity, pressure and UV index to Home Assistant via MQTT. Fully self-contained IP65 enclosure.",
  tech_stack: "ESP32-S3 · BME280 · VEML6075 · ESPHome · MQTT",
  notes: "IP65 enclosure mandatory. Rain gauge planned for v2.",
  budget: Decimal.new("450"),
  project_group_id: hw.id
})

{:ok, forge} = Projects.create_project(%{
  name: "Forge – Project Tracker",
  status: :active, color: :violet,
  description: "Personal project-management app built with Elixir, Phoenix LiveView and Ecto. Tracks tasks, BOM, journal entries and project groups with a clean, fast UI.",
  tech_stack: "Elixir · Phoenix LiveView · Ecto · PostgreSQL · Tailwind CSS",
  url: "https://github.com/example/forge",
  notes: "Keep UI minimal. Keyboard navigation and dark-mode are first-class.",
  budget: Decimal.new("0"),
  project_group_id: sw.id
})

{:ok, keyboard} = Projects.create_project(%{
  name: "Ortholinear Keyboard",
  status: :paused, color: :amber,
  description: "Custom 4×12 ortholinear keyboard with hot-swap sockets, per-key RGB and QMK firmware on an STM32F072. PCBs ordered from JLCPCB, awaiting delivery.",
  tech_stack: "KiCad · QMK · STM32F072 · WS2812B",
  notes: "Resume when PCBs arrive. Verify switch footprint tolerances before v2 order.",
  budget: Decimal.new("1200"),
  project_group_id: hw.id
})

{:ok, bench} = Projects.create_project(%{
  name: "Workshop Workbench",
  status: :done, color: :orange,
  description: "Heavy-duty laminated beech workbench with shoulder vise, tail vise and a full-length dog-hole strip. Finished and in daily use.",
  tech_stack: "Woodworking · Hand tools · Router",
  notes: "Apply second coat of Danish oil in ~6 months.",
  budget: Decimal.new("3200"),
  project_group_id: home.id
})

{:ok, irrigation} = Projects.create_project(%{
  name: "Smart Irrigation Controller",
  status: :idea, color: :blue,
  description: "Replace the dumb timer with an ESPHome node that reads soil-moisture sensors and checks a weather API before running each zone. Start with one zone PoC.",
  tech_stack: "ESP32 · Capacitive moisture sensors · ESPHome · Home Assistant",
  notes: "Validate soil-sensor accuracy first. Cheap capacitive sensors drift – may need individual calibration curves.",
  project_group_id: home.id
})

{:ok, cli} = Projects.create_project(%{
  name: "forge-cli",
  status: :idea, color: :rose,
  description: "Command-line companion for Forge. Capture tasks, journal notes and BOM items without opening the browser. Ships as a single binary via Burrito.",
  tech_stack: "Elixir · Burrito · REST API",
  notes: "Validate with two weeks of personal daily use before adding commands.",
  project_group_id: sw.id
})

{:ok, lap} = Projects.create_project(%{
  name: "Lap Timer – Data Logger",
  status: :active, color: :rose,
  description: "GPS-based lap timer and data logger for track days. Records speed, lateral g, throttle and brake traces. Syncs to a web dashboard after each session.",
  tech_stack: "ESP32-S3 · u-blox M10 GPS · MMA8452 · InfluxDB · Grafana",
  url: "https://github.com/example/lap-timer",
  notes: "Accuracy goal: ±0.05 s lap time. Logger must survive vibration and 60 °C in a closed car.",
  budget: Decimal.new("1800"),
  project_group_id: moto.id
})

{:ok, dash} = Projects.create_project(%{
  name: "Racecar Dashboard",
  status: :paused, color: :amber,
  description: "Compact CAN-bus dash showing RPM, water temp, gear and lap delta. Driving a 3.5\" TFT from an STM32H7 with LVGL. Paused while chassis work is ongoing.",
  tech_stack: "STM32H7 · LVGL · CAN bus · TFT 3.5\"",
  notes: "Resume after suspension rebuild is done. CAN DBC file needs updating for new ECU.",
  budget: Decimal.new("950"),
  project_group_id: moto.id
})

{:ok, api} = Projects.create_project(%{
  name: "Forge JSON API",
  status: :active, color: :blue,
  description: "RESTful JSON API layer on top of Forge using AshJsonApi. Powers the CLI and any future mobile client. Authentication via API tokens.",
  tech_stack: "Elixir · AshJsonApi · AshAuthentication · Phoenix",
  notes: "Keep versioning strategy simple – single v1 prefix, no hypermedia.",
  budget: Decimal.new("0"),
  project_group_id: sw.id
})

{:ok, cnc} = Projects.create_project(%{
  name: "CNC Router Enclosure",
  status: :idea, color: :orange,
  description: "Soundproofed and dust-contained enclosure for the 3018 CNC router. Lined with acoustic foam, filtered exhaust fan, acrylic viewing window and integrated LED lighting.",
  tech_stack: "Woodworking · Laser cut acrylic · 3D print",
  notes: "Aim for -20 dB. Check fire ratings on foam before ordering.",
  project_group_id: home.id
})

{:ok, reflow} = Projects.create_project(%{
  name: "Reflow Oven Conversion",
  status: :done, color: :rose,
  description: "Converted a £25 toaster oven into a proper SMD reflow oven using a PID controller, solid-state relay and a thermocouple. Profiles stored on SD card.",
  tech_stack: "STM32 · MAX31855 · SSR-40DA · PID",
  notes: "Calibrate yearly. Keep spare SSR on the shelf – they fail silently.",
  budget: Decimal.new("680"),
  project_group_id: hw.id
})

{:ok, ha} = Projects.create_project(%{
  name: "Home Assistant Dashboard",
  status: :active, color: :sky,
  description: "Custom Lovelace dashboard for the whole house. Room-by-room cards, energy monitoring panel, presence detection and alarm integration.",
  tech_stack: "Home Assistant · YAML · custom:button-card · ApexCharts",
  notes: "Mobile-first layout. Keep card count low – cognitive load matters.",
  project_group_id: home.id
})

{:ok, data_pipeline} = Projects.create_project(%{
  name: "Energy Monitor Pipeline",
  status: :paused, color: :emerald,
  description: "Reads Eastron SDM630 three-phase energy meter over RS-485 Modbus, pushes readings to InfluxDB every 10 s and visualises them in Grafana.",
  tech_stack: "ESP32 · RS-485 · Modbus RTU · InfluxDB · Grafana",
  notes: "Paused – need to run conduit to the meter board. Revisit in spring.",
  budget: Decimal.new("320"),
  project_group_id: hw.id
})

{:ok, mobile} = Projects.create_project(%{
  name: "Forge Mobile App",
  status: :idea, color: :violet,
  description: "Native iOS/Android companion for Forge using React Native. Offline-first with background sync. Quick-capture widget for tasks and journal entries.",
  tech_stack: "React Native · Expo · SQLite · REST",
  notes: "Don't start until the JSON API is stable. Evaluate Flutter as an alternative.",
  project_group_id: sw.id
})

# ── Tasks: blind ──────────────────────────────────────────────────────────

{:ok, adapter} = Projects.create_task(%{project_id: blind.id,
  title: "Design motor adapter bracket", status: :in_progress, priority: :high, pin_status: :current,
  description: "PETG bracket clamping to the spring tube with a D-profile bore for the N20 shaft."})
{:ok, _} = Projects.create_task(%{project_id: blind.id, parent_task_id: adapter.id,
  title: "Print tolerance test piece at 0.1 mm layers", status: :done, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: blind.id, parent_task_id: adapter.id,
  title: "Verify back-drive resistance on bench rig", status: :todo, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: blind.id,
  title: "Flash ESPHome firmware with position tracking", status: :todo, priority: :high, pin_status: :upcoming,
  description: "Configure stepper component, end-stop GPIOs and cover entity."})
{:ok, _} = Projects.create_task(%{project_id: blind.id,
  title: "Order DRV8833 driver boards (qty 3)", status: :blocked, priority: :medium,
  description: "Blocked on deciding quantity. 3 vs 5 units changes unit price significantly."})
{:ok, _} = Projects.create_task(%{project_id: blind.id,
  title: "Build breadboard test rig", status: :done, priority: :low})
{:ok, _} = Projects.create_task(%{project_id: blind.id,
  title: "Validate torque requirement", status: :done, priority: :medium,
  description: "Measured 18 mNm needed; N20 provides 30 mNm stall. Confirmed 1.6× margin."})

# ── Tasks: weather ────────────────────────────────────────────────────────

{:ok, enc} = Projects.create_task(%{project_id: weather.id,
  title: "Design IP65 enclosure", status: :in_progress, priority: :high, pin_status: :current})
{:ok, _} = Projects.create_task(%{project_id: weather.id, parent_task_id: enc.id,
  title: "Model cable gland entry holes", status: :todo, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: weather.id, parent_task_id: enc.id,
  title: "Add ventilation labyrinth for sensor accuracy", status: :todo, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: weather.id,
  title: "Wire BME280 to ESP32 on prototype board", status: :done, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: weather.id,
  title: "Calibrate UV index sensor against reference", status: :todo, priority: :medium, pin_status: :upcoming})
{:ok, _} = Projects.create_task(%{project_id: weather.id,
  title: "Set up MQTT discovery in Home Assistant", status: :todo, priority: :low})
{:ok, _} = Projects.create_task(%{project_id: weather.id,
  title: "24-hour solar charging baseline test", status: :done, priority: :medium,
  description: "6V 2W panel charged 1000 mAh from 10% to 80% in 5 h partial cloud."})

# ── Tasks: forge ─────────────────────────────────────────────────────────

{:ok, overview_t} = Projects.create_task(%{project_id: forge.id,
  title: "Build overview dashboard", status: :in_progress, priority: :high, pin_status: :current,
  description: "Cross-project view: status counts, pinned tasks, recent journal entries."})
{:ok, _} = Projects.create_task(%{project_id: forge.id, parent_task_id: overview_t.id,
  title: "Status summary widget row", status: :done, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: forge.id, parent_task_id: overview_t.id,
  title: "Pinned tasks panel grouped by project", status: :in_progress, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: forge.id, parent_task_id: overview_t.id,
  title: "Recent journal entries feed", status: :todo, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: forge.id,
  title: "Add drag-and-drop task reordering", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: forge.id,
  title: "Implement project groups", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: forge.id,
  title: "Add subtask support", status: :done, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: forge.id,
  title: "Write property-based tests for BOM budget logic", status: :todo, priority: :medium, pin_status: :upcoming})
{:ok, _} = Projects.create_task(%{project_id: forge.id,
  title: "Keyboard navigation throughout the app", status: :todo, priority: :low})

# ── Tasks: keyboard ───────────────────────────────────────────────────────

{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Finalise KiCad schematic", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Route PCB and send Gerbers to JLCPCB", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Await PCB delivery (order JL-88201)", status: :blocked, priority: :medium,
  description: "Estimated 2–3 weeks. Tracking number confirmed."})
{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Solder components and test switch matrix", status: :todo, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Flash QMK and configure default keymap", status: :todo, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: keyboard.id,
  title: "Lube Gateron Yellows with Krytox 205g0", status: :todo, priority: :low})

# ── Tasks: lap timer ─────────────────────────────────────────────────────

{:ok, gps_t} = Projects.create_task(%{project_id: lap.id,
  title: "GPS module integration", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: lap.id, parent_task_id: gps_t.id,
  title: "Evaluate u-blox M10 vs M9N accuracy", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: lap.id, parent_task_id: gps_t.id,
  title: "Configure 10 Hz NMEA output", status: :done, priority: :medium})
{:ok, log_t} = Projects.create_task(%{project_id: lap.id,
  title: "SD card data logger", status: :in_progress, priority: :high, pin_status: :current,
  description: "Write binary log format: GPS, IMU and ADC channels at 50 Hz. Target < 5 ms write latency."})
{:ok, _} = Projects.create_task(%{project_id: lap.id, parent_task_id: log_t.id,
  title: "Design binary log format spec", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: lap.id, parent_task_id: log_t.id,
  title: "Benchmark SPI write speed with DMA", status: :in_progress, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: lap.id,
  title: "Web dashboard: upload and visualise session", status: :todo, priority: :medium, pin_status: :upcoming})
{:ok, _} = Projects.create_task(%{project_id: lap.id,
  title: "Vibration test in car at circuit", status: :todo, priority: :high})

# ── Tasks: api ────────────────────────────────────────────────────────────

{:ok, _} = Projects.create_task(%{project_id: api.id,
  title: "Set up AshJsonApi routes for projects", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: api.id,
  title: "Implement API token authentication", status: :in_progress, priority: :high, pin_status: :current})
{:ok, _} = Projects.create_task(%{project_id: api.id,
  title: "Add pagination to task list endpoint", status: :todo, priority: :medium, pin_status: :upcoming})
{:ok, _} = Projects.create_task(%{project_id: api.id,
  title: "Write OpenAPI spec", status: :todo, priority: :low})

# ── Tasks: home assistant ─────────────────────────────────────────────────

{:ok, _} = Projects.create_task(%{project_id: ha.id,
  title: "Room-by-room overview cards", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: ha.id,
  title: "Energy monitoring panel with cost forecast", status: :in_progress, priority: :high, pin_status: :current})
{:ok, _} = Projects.create_task(%{project_id: ha.id,
  title: "Presence detection using BLE beacons", status: :todo, priority: :medium, pin_status: :upcoming})
{:ok, _} = Projects.create_task(%{project_id: ha.id,
  title: "Alarm integration and arm/disarm cards", status: :todo, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: ha.id,
  title: "Mobile companion view (portrait layout)", status: :todo, priority: :low})

# ── Tasks: reflow ────────────────────────────────────────────────────────

{:ok, _} = Projects.create_task(%{project_id: reflow.id,
  title: "Wire SSR-40DA and thermocouple", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: reflow.id,
  title: "PID tuning for SAC305 lead-free profile", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: reflow.id,
  title: "Implement SD card profile storage", status: :done, priority: :medium})
{:ok, _} = Projects.create_task(%{project_id: reflow.id,
  title: "Calibrate temperature accuracy against reference", status: :done, priority: :medium})

# ── Tasks: bench ─────────────────────────────────────────────────────────

{:ok, _} = Projects.create_task(%{project_id: bench.id,
  title: "Mill and laminate beech top (80 mm thick)", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: bench.id,
  title: "Fit shoulder vise hardware", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: bench.id,
  title: "Fit tail vise and dog holes", status: :done, priority: :high})
{:ok, _} = Projects.create_task(%{project_id: bench.id,
  title: "Apply two coats of Danish oil", status: :done, priority: :medium})


# ── BOM: blind ────────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: blind.id,
  name: "N20 worm-gear motor 12V 30 RPM", quantity: 2, supplier: "AliExpress",
  unit_price: Decimal.new("79"), status: :received,
  notes: "One spare. Verify shaft diameter before printing adapter."})
{:ok, _} = Projects.create_bom_item(%{project_id: blind.id,
  name: "DRV8833 dual H-bridge module", quantity: 3, supplier: "LCSC",
  unit_price: Decimal.new("25"), status: :ordered})
{:ok, _} = Projects.create_bom_item(%{project_id: blind.id,
  name: "ESP32-C3 mini dev board", quantity: 1, supplier: "AliExpress",
  unit_price: Decimal.new("45"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: blind.id,
  name: "PETG filament 1 kg – Prusament Galaxy Black", quantity: 1, supplier: "Prusa",
  unit_price: Decimal.new("299"), status: :needed})
{:ok, _} = Projects.create_bom_item(%{project_id: blind.id,
  name: "M3×8 socket-head screws (pack 50)", quantity: 1, supplier: "Würth",
  unit_price: Decimal.new("55"), status: :received})

# ── BOM: weather ──────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: weather.id,
  name: "ESP32-S3 WROOM-1 module", quantity: 2, supplier: "Mouser",
  unit_price: Decimal.new("89"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: weather.id,
  name: "BME280 breakout board", quantity: 2, supplier: "LCSC",
  unit_price: Decimal.new("38"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: weather.id,
  name: "VEML6075 UV index sensor breakout", quantity: 1, supplier: "Adafruit",
  unit_price: Decimal.new("75"), status: :ordered})
{:ok, _} = Projects.create_bom_item(%{project_id: weather.id,
  name: "6V 2W monocrystalline solar panel", quantity: 1, supplier: "AliExpress",
  unit_price: Decimal.new("99"), status: :needed})
{:ok, _} = Projects.create_bom_item(%{project_id: weather.id,
  name: "TP4056 LiPo charger module with protection", quantity: 1, supplier: "AliExpress",
  unit_price: Decimal.new("18"), status: :received})

# ── BOM: keyboard ─────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: keyboard.id,
  name: "Gateron Yellow linear switches (90 pcs)", quantity: 1, supplier: "KBDFans",
  unit_price: Decimal.new("349"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: keyboard.id,
  name: "Kailh hot-swap sockets (100 pcs)", quantity: 1, supplier: "AliExpress",
  unit_price: Decimal.new("89"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: keyboard.id,
  name: "Custom PCB 4×12 – 5 pcs JLCPCB ENIG", quantity: 1, supplier: "JLCPCB",
  unit_price: Decimal.new("420"), status: :ordered,
  notes: "Order JL-88201. ENIG finish, 1.2 mm."})
{:ok, _} = Projects.create_bom_item(%{project_id: keyboard.id,
  name: "WS2812B LEDs 0603 (100 pcs)", quantity: 1, supplier: "LCSC",
  unit_price: Decimal.new("95"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: keyboard.id,
  name: "STM32F072CBT6 QFP48", quantity: 5, supplier: "Mouser",
  unit_price: Decimal.new("62"), status: :received})

# ── BOM: bench ────────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: bench.id,
  name: "European beech 50×200 mm × 6 m", quantity: 8, supplier: "Local sawmill",
  unit_price: Decimal.new("280"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: bench.id,
  name: "Dictum shoulder vise hardware kit", quantity: 1, supplier: "Dictum",
  unit_price: Decimal.new("890"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: bench.id,
  name: "Danish oil 1 L", quantity: 2, supplier: "Byggmax",
  unit_price: Decimal.new("149"), status: :received})

# ── BOM: lap timer ────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: lap.id,
  name: "ESP32-S3-WROOM-2 16 MB", quantity: 2, supplier: "Mouser",
  unit_price: Decimal.new("115"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: lap.id,
  name: "u-blox NEO-M10S GPS module", quantity: 1, supplier: "Mouser",
  unit_price: Decimal.new("389"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: lap.id,
  name: "MMA8452Q 3-axis accelerometer breakout", quantity: 2, supplier: "SparkFun",
  unit_price: Decimal.new("149"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: lap.id,
  name: "Industrial microSD 32 GB (SLC)", quantity: 2, supplier: "Mouser",
  unit_price: Decimal.new("229"), status: :ordered})
{:ok, _} = Projects.create_bom_item(%{project_id: lap.id,
  name: "Custom logger PCB v1 (10 pcs)", quantity: 1, supplier: "JLCPCB",
  unit_price: Decimal.new("640"), status: :needed})

# ── BOM: reflow ───────────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: reflow.id,
  name: "SSR-40DA solid-state relay", quantity: 2, supplier: "AliExpress",
  unit_price: Decimal.new("149"), status: :received,
  notes: "Buy two – they fail silently. Keep one spare."})
{:ok, _} = Projects.create_bom_item(%{project_id: reflow.id,
  name: "MAX31855 thermocouple breakout", quantity: 1, supplier: "Adafruit",
  unit_price: Decimal.new("189"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: reflow.id,
  name: "K-type thermocouple probe 300 °C", quantity: 2, supplier: "AliExpress",
  unit_price: Decimal.new("45"), status: :received})

# ── BOM: data pipeline ────────────────────────────────────────────────────

{:ok, _} = Projects.create_bom_item(%{project_id: data_pipeline.id,
  name: "Eastron SDM630 3-phase energy meter", quantity: 1, supplier: "RS Components",
  unit_price: Decimal.new("1250"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: data_pipeline.id,
  name: "TTL to RS-485 module", quantity: 2, supplier: "AliExpress",
  unit_price: Decimal.new("22"), status: :received})
{:ok, _} = Projects.create_bom_item(%{project_id: data_pipeline.id,
  name: "DIN rail ESP32 enclosure", quantity: 1, supplier: "Bopla",
  unit_price: Decimal.new("245"), status: :needed})


# ── Journal: blind ────────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: blind.id,
  title: "Torque calculation confirmed",
  body: "Weighed the blind at 420 g and measured the arm. Peak torque required: ~18 mNm. N20 spec shows 30 mNm stall – 1.6× margin. Proceeding with this motor family."})
{:ok, _} = Projects.create_journal_entry(%{project_id: blind.id,
  title: "Adapter prototype v1 – first print results",
  body: "Printed at 0.2 mm in PETG. Fits the tube but the D-bore is 0.3 mm too tight. Adjusting CAD tolerance from 0.1 to 0.2 mm clearance. Next: reprint and check fit before proceeding."})
{:ok, _} = Projects.create_journal_entry(%{project_id: blind.id,
  title: "ESPHome YAML skeleton working",
  body: "Drafted the basic YAML: stepper component, two cover end-stops on GPIO 4 and 5, direction inversion flag. Motor changes direction correctly on bench. Still need position tracking and calibration routine."})

# ── Journal: weather ──────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: weather.id,
  title: "BME280 24-hour accuracy test",
  body: "Ran BME280 alongside a calibrated Vaisala reference for 24 h indoors. Temperature error: ±0.3 °C, humidity: ±2 %RH. Both within spec. No software compensation needed at this stage."})
{:ok, _} = Projects.create_journal_entry(%{project_id: weather.id,
  title: "Solar charging baseline established",
  body: "6V 2W panel into TP4056 charged a 1000 mAh cell from 10% to 80% in 5 h of partial cloud. ESP32-S3 deep-sleep draws ~12 µA – battery life estimated at 3 months without sun. Acceptable for garden use."})
{:ok, _} = Projects.create_journal_entry(%{project_id: weather.id,
  title: "Enclosure design decision: Stevenson screen vs custom",
  body: "Evaluated printing a Stevenson screen vs a simple vented box. Decided on a vented labyrinth design: smaller, less conspicuous, and printable in one piece. Will add a radiation shield overhang above the sensor port."})

# ── Journal: forge ────────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: forge.id,
  title: "Project groups shipped",
  body: "Finished project groups: grouping on the index view, assignment in the form, and per-group status filters. All existing projects migrated. The grouped layout makes the index page significantly easier to scan."})
{:ok, _} = Projects.create_journal_entry(%{project_id: forge.id,
  title: "Overview dashboard design session",
  body: "Sketched the layout: status-count row at top, pinned-task panels by project in the middle, recent journal entries at the bottom. Going with LiveView streams for the journal list to avoid full re-renders."})
{:ok, _} = Projects.create_journal_entry(%{project_id: forge.id,
  title: "Performance check with realistic data",
  body: "Seeded 15 projects, 80 tasks, 30 BOM items and 40 journal entries. Index page mounts in < 30 ms. preload_pinned_tasks/1 runs a single extra query regardless of project count – good. Will revisit when the journal list gets paginated."})

# ── Journal: keyboard ────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: keyboard.id,
  title: "PCB order placed at JLCPCB",
  body: "Uploaded Gerbers. ENIG finish, 1.2 mm FR-4, tented vias. Order JL-88201. Estimated 14 business days. Using the wait to flesh out the QMK keymap and set up the firmware repo."})
{:ok, _} = Projects.create_journal_entry(%{project_id: keyboard.id,
  title: "Switch selection rationale",
  body: "Compared Gateron Yellow, Boba U4T and Holy Pandas at a local meetup. Settled on Gateron Yellow for smooth linear feel at a sane price point. Will lube with Krytox 205g0 and film before assembly."})

# ── Journal: lap timer ────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: lap.id,
  title: "GPS accuracy shootout: M10 vs M9N",
  body: "Drove a 5 km test loop 10 times with both modules logging simultaneously. M10 shows 0.8 m CEP vs M9N's 1.2 m CEP. Both are fine for lap timing, but the M10's 10 Hz update rate gives much smoother trace data. Going with M10."})
{:ok, _} = Projects.create_journal_entry(%{project_id: lap.id,
  title: "Binary log format v1 decided",
  body: "Log frame: 4-byte magic, 4-byte timestamp (ms), 4-byte lat, 4-byte lon, 2-byte speed, 3× 2-byte IMU axes, 1-byte checksum = 24 bytes/frame at 50 Hz = 72 kB/min. A 32 GB card holds 7400 hours. More than enough."})
{:ok, _} = Projects.create_journal_entry(%{project_id: lap.id,
  title: "First track session with prototype",
  body: "Ran 12 laps at Mantorp Park. Logger survived the vibration and 58 °C cabin temp. GPS lock acquired in < 15 s in the paddock. Lap delta display was motivating! SD write had two 8 ms spikes – investigating DMA buffer flushing."})

# ── Journal: bench ────────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: bench.id,
  title: "Benchtop lamination complete",
  body: "Glued up 8 beech boards in two stages. Final top is 840 mm wide and 78 mm thick. Flattened with a router sled – took three hours but the result is within 0.3 mm over 2 m. Very happy."})
{:ok, _} = Projects.create_journal_entry(%{project_id: bench.id,
  title: "Shoulder vise fitting – minor adjustment needed",
  body: "The guide rod hole needed 0.5 mm reamed out – minor. Vise now closes with zero racking. Tail vise slides smoothly without play. First use for cutting dovetails – rock solid. Project complete."})

# ── Journal: reflow ───────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: reflow.id,
  title: "PID tuned for SAC305 lead-free profile",
  body: "Used Ziegler-Nichols to get initial PID params then tweaked manually. Peak temp 249 °C, 22 s above liquidus, 4 °C/s cooling slope. Reflowed a test board – all joints shiny and well-formed. Calling this done."})

# ── Journal: home assistant ───────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: ha.id,
  title: "Lovelace layout v3 – much cleaner",
  body: "Dropped the old Mushroom cards for custom button-cards with consistent styling. Removed 14 cards that nobody used. Dashboard now loads in 1.2 s on the wall tablet vs 3.4 s before. Less is more."})
{:ok, _} = Projects.create_journal_entry(%{project_id: ha.id,
  title: "Energy panel – solar vs grid data live",
  body: "Connected the Eastron meter data via MQTT. Real-time grid/solar/battery power flow gauge is working. Cost forecast uses the Nordpool electricity price integration – fascinating to see the spot-price curve."})

# ── Journal: api ─────────────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: api.id,
  title: "AshJsonApi routes up for projects and tasks",
  body: "Standard CRUD endpoints working for projects and tasks. Relationship sideloading works via ?include= param. Pagination defaults to 25 per page. Next: authentication middleware."})

# ── Journal: data pipeline ────────────────────────────────────────────────

{:ok, _} = Projects.create_journal_entry(%{project_id: data_pipeline.id,
  title: "Modbus polling working on prototype",
  body: "ESP32 reads all 60 registers of the SDM630 over RS-485 in ~140 ms. Data pushed to InfluxDB via HTTP. Grafana dashboard showing power factor per phase and THD. Pausing now until conduit is run to the meter board."})

IO.puts("Seeds complete!")
