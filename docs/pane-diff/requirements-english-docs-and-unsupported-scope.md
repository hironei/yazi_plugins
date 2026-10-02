# Requirements: English Documentation and Unsupported Scope Tracking

## Goal

Make the repository language policy explicit and create an actionable tracking boundary for functionality that is currently unsupported or cannot be validated by the Lua mock tests.

## Functional requirements

1. Add a repository-level `AGENTS.md` stating that deliverables, README files, and UserManual files are written in English.
2. Translate the existing repository and plugin README files to English without changing the plugin's runtime behavior or installation commands.
3. Document the currently unsupported behavior and the live-environment checks that remain outside automated test coverage.
4. Create a GitHub Issue in English covering the remaining unsupported scope and its acceptance criteria.

## Non-functional requirements

- Keep the existing Git Bash and WSL support wording and package-manager commands accurate.
- Preserve the active-pane-first argument order and the documented absence of a physical left/right mapping.
- Do not add a dependency, change the plugin API, or invent a private `split-tabs.yazi` integration.
- Do not claim live Yazi, external Diff GUI, Windows focus, or IME validation from the Lua mock test.

## Acceptance criteria

- `AGENTS.md` contains the English-language rule for deliverables, README, and UserManual files.
- `README.md` and `pane-diff.yazi/README.md` are English and retain the documented setup, operation, limitations, and test command.
- The unsupported scope is explicit, actionable, and linked to [Issue #2 in the original repository](https://github.com/hironei/yazi_split_pane_diff/issues/2).
- `lua tests/pane-diff/test_main.lua` passes.
- `git diff --check` passes.
