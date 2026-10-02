# Requirements: Yazi 26.8.15 Compatibility and Target-Agnostic Difftool Launching

## Goal

Make `pane-diff.yazi` compatible with the Yazi 26.8.15 `tab.selected` contract and pass one selected or hovered file or folder from each pane directly to the Git-configured Diff tool.

## Functional requirements

1. Resolve a selected Yazi `File` entry through its `.url` before validation and command construction.
2. Preserve compatibility with older selected entries that are already URL-like values.
3. Preserve the existing target-selection rules: one selected item takes precedence over the hovered item, no selection uses the hovered item, and multiple selections are rejected.
4. Reject unavailable targets, but do not classify selected or hovered targets by file, folder, link, or special-file type.
5. Read `diff.tool` and `difftool.<tool>.path` from Git; if no explicit path is configured, use the configured tool name as a `PATH` command.
6. Invoke the resolved Diff tool directly with the two target paths as separate arguments.
7. Continue reporting launch failures, wait failures, and abnormal exit statuses.

## Non-functional requirements

- Keep Yazi-version compatibility logic localized to a small adapter.
- Do not add dependencies, fetcher API changes, shell command construction, or unrelated refactoring.
- Document the Yazi 26.8.15 tested baseline and the retained older URL-entry compatibility.
- Keep the live-validation boundary explicit: Lua mocks do not prove Yazi, split-tabs, or the configured external Diff tool behavior.

## Acceptance criteria

- A Yazi 26.8.15-shaped selected `File` passes its actual URL path to the resolved Diff tool.
- A selected or hovered folder and a selected or hovered file are passed unchanged as target paths.
- A direct URL-shaped selected value remains supported.
- Selected-target, selected-plus-hovered, hovered-only, mixed file/folder, multiple-selection, and unavailable-target behavior is covered by tests.
- The Git-configured tool path is passed as the process executable and the two paths are separate arguments.
- Launch and wait failures still create error notifications.
- `lua tests/pane-diff/test_main.lua` and `git diff --check` pass.
- Documentation and the `@since` compatibility comment agree with the supported baseline.
