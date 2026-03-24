Contributing to Forge
=====================

Thanks for your interest in contributing! By contributing, you agree that your contributions will be licensed under the project's license (GNU GPL v3.0 only).

Getting started
---------------

1. Read the README and AGENTS.md for project conventions and tooling.
2. Run `mix setup` to prepare your environment.
3. Run the test suite: `mix test`.

Branching & PR flow
-------------------

- Fork the repo and create a branch: `feature/<short-description>` or `fix/<short-description>`
- Open a PR to the main branch with a clear description of the change and testing instructions.

Code style & tests
------------------

- Format: `mix format`
- Tests are required for new features and bug fixes. Prefer StreamData-driven property tests for domain logic.
- Follow the project's AGENTS.md rules: domain logic in Ash resources, LiveView handles presentation.

License & legal
----------------

By contributing, you grant the project the rights to use your contribution under the project's license (GPL-3.0-or-later).

If you have questions about contributions or licensing, open an issue to discuss them.
