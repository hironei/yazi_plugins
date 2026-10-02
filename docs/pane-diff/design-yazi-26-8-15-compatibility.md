# Design: Yazi 26.8.15 Compatibility and Target-Agnostic Difftool Launching

## Scope

Update the existing Lua plugin, its mock tests, and English documentation. No dependency, public plugin command, or fetcher behavior changes are required.

## Selected-entry normalization

Keep a local `resolve_url` helper at the selection boundary. It returns `entry.url` for the Yazi 26.8.15 `File` shape and returns the entry itself for the older direct URL shape. The resolved value is converted to a string without inspecting its file type, so files, folders, links, and special files follow the same path flow.

The helper is intentionally version-free: the presence of `.url` selects the new representation, while the fallback preserves the earlier representation. The active-pane-first ordering and separate command arguments remain unchanged.

Target validation is limited to the presence of a resolved URL. The selection count and hovered-target fallback remain unchanged.

## Git-configured Diff tool resolution

Read `diff.tool` and `difftool.<tool>.path` with `Command("git"):output()`. Use the explicit path when present, otherwise use the tool name as a command expected in `PATH`. Invoke that resolved executable directly with `{ left, right }` as separate `Command:arg` values. This avoids Git's `difftool` directory expansion and works for tools such as WinMerge and Beyond Compare.

The plugin does not reinterpret `difftool.<tool>.cmd`, because it is a shell template intended for Git's file-oriented invocation. Users who need direct folder comparison should configure `difftool.<tool>.path`.

## Difftool exit-status handling

The direct Diff tool's process status is monitored. Launch errors, wait errors, and every non-success status are reported; the previous Git `--no-index` exit-code exception no longer applies.

The child status API reports the direct tool's process result. No status code is treated as a Git-specific difference result because Git's `--no-index` wrapper is not used.

## Test seams and traceability

- Mock selected entries model both Yazi 26.8.15 `File` values and older direct URL values.
- Mock selected and hovered files and folders, mixed target kinds, Git tool/path lookup, and child statuses.
- Existing path-preservation and selection-count cases remain in the same test harness.
- User-facing documentation describes the compatibility adapter, direct Git-configured tool launch, and the live Yazi/external-tool acceptance boundary.
