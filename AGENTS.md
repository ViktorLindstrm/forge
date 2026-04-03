# AGENTS.md

## Purpose
This file defines the project's mandatory guidelines for implementation, architecture, testing, UI, and workflow. These guidelines apply to the entire project and should be followed as far as is practically possible.

## Workflow
- Run relevant tests when all changes are complete and fix any remaining issues before finishing work.
- Use `Req` for HTTP requests when needed. Avoid `:httpoison`, `:tesla`, and `:httpc`.

## Architecture and responsibility

### Technology priority order
Always follow this strict priority order when deciding how to implement any feature or behaviour:

1. **Ash Framework first** — Model all domain logic, state, validation, data access, and business rules using Ash resources, actions, validations, changes, calculations, and policies. If something can be expressed in Ash, it must be.
2. **Phoenix LiveView second** — Only reach for LiveView (events, assigns, socket state) when the requirement is genuinely about UI interaction, presentation, or orchestration that cannot be expressed in Ash alone. LiveView should never re-implement what Ash already provides.
3. **Custom JavaScript last resort** — Only write custom JavaScript (hooks, `phx-hook`, JS commands) when the requirement is physically impossible to fulfil in Ash or LiveView — for example, direct DOM manipulation, browser APIs, or third-party JS library integration. Before writing any JS, explicitly verify that no LiveView built-in (`phx-click`, `phx-change`, `JS.*`, streams, etc.) can cover the need.

If you find yourself writing JavaScript to work around a server-side state problem, stop and solve the state problem in Ash or LiveView instead.

### General architecture rules
- Build the project on **Ash Framework 3.0**.
- Model core domain logic with **Ash resources, actions, validations, changes, and policies**.
- Prefer Ash's declarative and built-in patterns over custom special-purpose logic when they are sufficient.
- Do not place business logic in LiveView or UI layers if it can be expressed more clearly in Ash.
- LiveView should primarily handle presentation, interaction, and orchestration.
- Keep implementations modular, small, and clearly scoped.
- Prefer simple, reusable code over over-engineering.
- Follow existing project patterns unless they conflict with these guidelines.
- If a task requires a deviation from these guidelines, or if multiple reasonable interpretations exist, pause and ask before implementing.

## Elixir and typing
- Use **Elixir 1.20**; RC versions are acceptable if needed.
- Follow **Elixir 1.20's type system and typing conventions** as far as is practically possible.
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
- Follow Phoenix v1.8's recommended layout patterns where relevant to this project.
- Use `<.icon>` for icons when Phoenix core components are used.
- Use `<.input>` for form fields when Phoenix core components are used and when this does not conflict with Petal Components or the project's UI standard.
- Avoid deprecated LiveView functions such as `live_redirect` and `live_patch`; instead use `push_navigate`, `push_patch`, and `<.link navigate={...}>` / `<.link patch={...}>`.
- Use LiveView streams for lists when appropriate.
- Avoid `LiveComponent` unless there is a clear need for it.
- Use `phx-hook` only when necessary, and combine it with appropriate DOM handling according to LiveView patterns.

## JavaScript and CSS
- Use Tailwind CSS for the interface.
- Follow the project's existing import syntax in `app.css` if Tailwind v4 is used.
- Avoid `@apply` in raw CSS.
- Avoid inline `<script>` tags in templates.
- Custom JavaScript (`phx-hook`, JS files) is a **last resort**. Before writing any JS, confirm that the same result cannot be achieved with `phx-click`, `phx-change`, `phx-value-*`, `JS.*` commands, LiveView assigns, or server-side state. If it can be done server-side, it must be done server-side.
- If client-side logic is genuinely required, place it in the designated JS files or use colocated hooks according to the project's established patterns.

## Testing
- **StreamData** should be the default for testing.
- `ExUnit.Case` may be used as the test framework for executing StreamData tests.
- Test logic should always be StreamData-driven and property-based.
- Use stable, small, focused tests with clear DOM IDs and selectors when testing UI.
- When needed, use `Phoenix.LiveViewTest` and element-based assertions instead of testing raw HTML directly.
- Whenever a new feature or function is added, create additional StreamData property based tests to validate.

### Integration tests for every feature
- Every new feature or significant change **must** include at least one end-to-end StreamData integration test that exercises the full user flow in a single `check all` block.
- The integration test must cover the complete interaction sequence from start to finish. For example, for the note preview feature this means: open the note form, type markdown text, switch to preview and assert the rendered output is correct, switch back to write mode and assert the original source text is unchanged, then submit the note and assert it is persisted.
- More detailed or edge-case scenarios are encouraged as additional separate property tests, but the mandatory integration test must walk the entire feature flow end to end.
- Integration tests should live in a clearly named file such as `*_integration_test.exs` or in a dedicated `describe "full flow"` block within the feature's test file.

### Integration test coverage requirements
The integration test must assert all observable side-effects and state transitions of the feature. In particular:

- **Data round-trips**: Any value entered by the user must be explicitly asserted to still be present after each state transition. For example, if a user types text and then navigates to a different view and back, the test must assert that the text is still present in the rendered HTML — not just that the page renders without error.
- **No assumption of implicit persistence**: Do not rely on the assumption that data "probably survived" a transition. Assert it explicitly with `assert html =~ value` after every step that could plausibly lose it.
- **Bidirectional transitions**: When a feature involves toggling between two modes (e.g. write/preview, collapsed/expanded, edit/view), the test must traverse the full cycle in both directions and assert correct state at each step.
- **Failure messages**: Assertions in integration tests must include a descriptive `message` argument so that failures clearly identify which step in the flow failed and what was expected.
- **Submission and persistence**: After submitting or saving, the test must assert both that the UI reflects the saved state and that the data exists in the database (e.g. via the relevant `Projects.*` or Ash query function).

## Integration and operations
- **Tidewave** should be integrated, but only in the **dev** environment.
- Use current stable versions from hex.pm when versions need to be chosen.
- Do not change dependencies, versions, or technical choices unless the task requires it.

## Miscellaneous
- Use Elixir's standard library for date and time manipulation when that is sufficient.
- Do not use `String.to_atom/1` on user input.
- Use `Task.async_stream/3` for parallel enumeration when appropriate.
- Write code that is clear, testable, and easy to maintain.
