[![License](https://img.shields.io/badge/license-GPL--3.0--only-blue.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Made with Elixir](https://img.shields.io/badge/made%20with-Elixir-4B275F.svg?style=flat-square)](https://elixir-lang.org/)
[![Phoenix LiveView](https://img.shields.io/badge/Phoenix-LiveView-792EE5.svg?style=flat-square)](https://hexdocs.pm/phoenix_live_view/)

# Forge 🔥

> Your project-forge — where ideas get shaped into something real.

Forge is a Phoenix LiveView application for managing projects, tasks, bills-of-material (BOMs), and journal entries. Built on the Ash Framework with Petal Components for a clean, responsive UI — it keeps your work organized without getting in the way.

---

## 📸 Screenshots

**Projects overview**

<p align="center">
  <img src="docs/screenshot-overview.png" alt="Forge projects overview" width="850"/>
</p>

**Project detail**

<p align="center">
  <img src="docs/screenshot-project.png" alt="Forge project detail view" width="850"/>
</p>

---

## ✨ Features

| | Feature | Description |
|--|---------|-------------|
| 📁 | **Projects** | Create, categorize, and track status: idea → active → paused → done |
| ✅ | **Tasks** | Hierarchical tasks with priorities, pinning, due dates, and drag-to-sort |
| 🔩 | **BOM** | Manage components and estimated costs per project |
| 📓 | **Notes** | Notes and logs attached to each project |
| 📊 | **Status overview** | At-a-glance project counts by status with pinned task highlights on each card |

---

## 🚀 Getting started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose

### 1. Download the compose file and generate a secret

```bash
curl -fsSL https://raw.githubusercontent.com/ViktorLindstrm/forge/main/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/ViktorLindstrm/forge/main/bin/init-secrets.sh -o init-secrets.sh
sh init-secrets.sh
```

The script generates a `SECRET_KEY_BASE` and saves it to a `.env` file. It is safe to re-run — it will never overwrite an existing secret.

> **Using a release artifact?** If you downloaded `docker-compose.prod-release.yml` from the [Releases](../../releases) page, rename it to `docker-compose.yml` and still run `init-secrets.sh` above to generate the required `.env` file before starting.

### 2. Configure your host

Edit `docker-compose.yml` and set `PHX_HOST` to your server's IP or hostname:

```yaml
environment:
  PHX_HOST: "192.168.1.100"   # or e.g. forge.lan
  PHX_SCHEME: "http"
  PORT: "80"                  # must match the external port in `ports:`
```

### 3. Start

```bash
docker compose up -d
```

Open `http://your-host-or-ip` in your browser.

---

## ⚙️ Configuration reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | ✅ | Secret used to sign sessions. Generate with the command above. |
| `DATABASE_URL` | ✅ | Postgres connection string: `ecto://USER:PASS@HOST/DB` |
| `PHX_HOST` | ✅ | The hostname or IP used to reach the app externally |
| `PHX_SCHEME` | | `http` (default) or `https` |
| `PORT` | | External port (default `4000`). Set to `80` or `443` to omit port from URLs. |
| `PHX_EXTRA_HOSTS` | | Comma-separated list of additional allowed hostnames, e.g. `localhost,192.168.1.5` |
| `POOL_SIZE` | | Database connection pool size (default `10`) |

---

## 🏗️ Architecture

The domain model is built on [Ash Framework](https://ash-hq.org/) resources. An auto-generated entity-relationship diagram is kept up to date in [`docs/architecture.md`](docs/architecture.md).

---

## 🛠 Tech stack

| | Layer | Technology |
|--|-------|------------|
| 💜 | Language | Elixir 1.20 |
| 🔥 | Web framework | Phoenix 1.8 + Phoenix LiveView |
| 🌿 | Domain modeling | Ash Framework 3.x + AshPostgres |
| 🎨 | UI | Petal Components + Tailwind CSS |
| 🐘 | Database | PostgreSQL |
| 🌐 | HTTP client | Req |
| 🧱 | Architecture | Ash resources, actions, validations, policies |
| 🧪 | Testing | StreamData property-based tests |
| 🛠 | Dev tools | Tidewave (dev only), Igniter (dev) |

---

## 🤝 Contributing

Want to hack on Forge locally? See [CONTRIBUTING.md](CONTRIBUTING.md) for how to set up a local Elixir development environment, coding standards, and the PR process.

---

## 📜 Community & Code of Conduct

This project is open and welcoming to everyone. Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for our community standards.

---

## 🔒 Security

Found a vulnerability? Please do **not** open a public issue. Instead, use [GitHub's private security advisory](../../security/advisories/new) to report it confidentially. See [SECURITY.md](SECURITY.md) for details.

---

## ⚖️ License

Forge is licensed under the **GNU General Public License v3.0 (GPL-3.0-only)**.  
Copyright © 2026 Viktor Lindström. See [LICENSE](LICENSE) for the full text.
