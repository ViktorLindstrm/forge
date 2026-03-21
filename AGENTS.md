# AGENTS.md

## Purpose
This file defines the project’s mandatory guidelines for implementation, architecture, testing, UI, and workflow. These guidelines apply to the entire project and should be followed as far as is practically possible.

## Workflow
- Run relevant tests when all changes are complete and fix any remaining issues before finishing work.
- Use `Req` for HTTP requests when needed. Avoid `:httpoison`, `:tesla`, and `:httpc`.

## Architecture and responsibility
- Build the project on **Ash Framework 3.0**.
- Model core domain logic with **Ash resources, actions, validations, changes, and policies**.
- Prefer Ash’s declarative and built-in patterns over custom special-purpose logic when they are sufficient.
- Do not place business logic in LiveView or UI layers if it can be expressed more clearly in Ash.
- LiveView should primarily handle presentation, interaction, and orchestration.
- Keep implementations modular, small, and clearly scoped.
- Prefer simple, reusable code over over-engineering.
- Follow existing project patterns unless they conflict with these guidelines.
- If a task requires a deviation from these guidelines, or if multiple reasonable interpretations exist, pause and ask before implementing.

## Elixir and typing
- Use **Elixir 1.20**; RC versions are acceptable if needed.
- Follow **Elixir 1.20’s type system and typing conventions** as far as is practically possible.
- Prefer clear types, typespecs, and type-driven design where it improves readability, safety, and maintainability.
- Ensure strict type definitions according to Elixir 1.20 spec. 

## Database, API, and authentication
- **AshPostgres** is the default unless otherwise specified.
- **AshJsonApi** is the default unless otherwise specified.
- **AshAuthentication** should be used when authentication is requested.

## Frontend and UI
- **Phoenix LiveView** should be used.
- **Petal Components** should be used for all design and UI.
- Custom HEEx components are only allowed when they complement Petal Components and do not duplicate or replace existing functionality.
- Use consistent, accessible, and clearly named DOM IDs for important elements in templates.

## Phoenix and LiveView guidelines
- Follow Phoenix v1.8’s recommended layout patterns where relevant to this project.
- Use `<.icon>` for icons when Phoenix core components are used.
- Use `<.input>` for form fields when Phoenix core components are used and when this does not conflict with Petal Components or the project’s UI standard.
- Avoid deprecated LiveView functions such as `live_redirect` and `live_patch`; instead use `push_navigate`, `push_patch`, and `<.link navigate={...}>` / `<.link patch={...}>`.
- Use LiveView streams for lists when appropriate.
- Avoid `LiveComponent` unless there is a clear need for it.
- Use `phx-hook` only when necessary, and combine it with appropriate DOM handling according to LiveView patterns.

## JavaScript and CSS
- Use Tailwind CSS for the interface.
- Follow the project’s existing import syntax in `app.css` if Tailwind v4 is used.
- Avoid `@apply` in raw CSS.
- Avoid inline `<script>` tags in templates.
- If client-side logic is needed, place it in the designated JS files or use colocated hooks according to the project’s established patterns.

## Testing
- **StreamData** should be the default for testing.
- `ExUnit.Case` may be used as the test framework for executing StreamData tests.
- Test logic should always be StreamData-driven and property-based.
- Use stable, small, focused tests with clear DOM IDs and selectors when testing UI.
- When needed, use `Phoenix.LiveViewTest` and element-based assertions instead of testing raw HTML directly.
- Whenever a new feature or function is added, create additional StreamData property based tests to validate.

## Integration and operations
- **Tidewave** should be integrated, but only in the **dev** environment.
- Use current stable versions from hex.pm when versions need to be chosen.
- Do not change dependencies, versions, or technical choices unless the task requires it.

## Miscellaneous
- Use Elixir’s standard library for date and time manipulation when that is sufficient.
- Do not use `String.to_atom/1` on user input.
- Use `Task.async_stream/3` for parallel enumeration when appropriate.
- Write code that is clear, testable, and easy to maintain.
