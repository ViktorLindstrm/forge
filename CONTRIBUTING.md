Contributing to Forge
=====================

Thanks for your interest in contributing! By contributing, you agree that your contributions will be licensed under the project's license (GNU GPL v3.0 only).

Local development setup
-----------------------

### Prerequisites

- Elixir >= 1.20
- Erlang/OTP compatible with Elixir 1.20
- PostgreSQL >= 12

### Setup

```bash
# 1. Install dependencies, set up database, build assets, and seed data
mix setup

# 2. Start the development server
mix phx.server
# or with an interactive shell:
iex -S mix phx.server
```

Open [`localhost:4000`](http://localhost:4000) in your browser.

### Useful aliases

```bash
mix ecto.setup       # Create, migrate, and seed the database
mix ecto.reset       # Drop and re-run ecto.setup
mix assets.setup     # Install Tailwind and esbuild if missing
mix assets.build     # Build frontend assets
mix assets.deploy    # Minify and digest for production
mix precommit        # Compile (warnings-as-errors), format, test — run before pushing
```

### Testing

```bash
mix test
```

Tests run `ash.setup` automatically via the test alias. Prefer StreamData-driven property tests for domain logic.

Branching & PR flow
-------------------

- Fork the repo and create a branch: `feature/<short-description>` or `fix/<short-description>`
- Open a PR to the main branch with a clear description of the change and testing instructions.

Code style & standards
-----------------------

- Format: `mix format`
- Tests are required for new features and bug fixes. Prefer StreamData-driven property tests for domain logic.
- **Domain logic belongs in Ash resources** — use actions, validations, changes, and policies. Keep LiveView for presentation and orchestration only.
- **HTTP calls**: use `Req`. Do not use `:httpoison`, `:tesla`, or `:httpc`.
- **UI**: use Petal Components; add custom HEEx components only when they complement (not replace) Petal.
- **Typing**: follow Elixir 1.20 typing conventions; use typespecs where they add clarity.
- Follow the full guidelines in [AGENTS.md](AGENTS.md).

License & legal
----------------

By contributing, you grant the project the rights to use your contribution under the project's license (GPL-3.0-only).

If you have questions about contributions or licensing, open an issue to discuss them.
