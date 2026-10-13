# Zoxide picker design

The required behavior is defined in [requirements.md](requirements.md). The package [README](../../zoxide-picker.yazi/README.md) provides standalone user instructions; [examples](../../examples/zoxide-picker/) contain copyable configuration.

## Configuration and Yazi context

`main.lua` returns a plugin table with `setup` and async `entry`. `setup` validates the executable and dense argv array, copies argv into owned main-context configuration, and clears any previous valid configuration if the new setup is invalid. It returns a boolean and optional error string; invocation reports the stored error. No implicit command is selected.

The async module is loaded separately from the module used by `init.lua`. A `ya.sync` snapshot retrieves setup state and `cx.tab.current.cwd` from Yazi's plugin state. Async entry uses the supplied `job.tab` for its eventual navigation event. The snapshot avoids reading the subsequently active tab and avoids depending on async module-local setup fields.

The current [upstream Zoxide plugin](https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/zoxide.lua) uses `cx.tab` and tab-targeted emission; the [entry job definition](https://github.com/sxyazi/yazi/blob/main/yazi-runner/src/entry/job.rs) supplies `job.tab`. The older v26.9.1 preset uses `cx.active` without tab-targeted emission, so this new package explicitly requires the current tab APIs. Existing packages' older baseline claims do not establish compatibility for this package. Missing tab/context support produces an actionable upgrade error before launching a picker.

## Process and byte flow

1. Check configuration, invoking-tab availability, and unsupported CR/LF in the invoking directory.
2. Execute `Command("zoxide"):arg { "query", "--list", "--exclude", cwd }` with null stdin and piped stdout/stderr. `Command:output()` drains both output streams and obtains exit status. Failed or missing status is an error; successful empty output ends without hiding Yazi.
3. Parse UTF-8 candidate records in original order. Accept LF/CRLF framing and an optional unterminated final record; reject malformed UTF-8, NULs, blank records, and embedded CR. Reassemble LF-delimited stdin without trimming spaces, sorting, changing slashes, or converting paths. Maintain a membership set alongside the ordered buffer for validating selection.
4. Acquire `ui.hide()`'s permit. Launch `Command(config.command):arg(config.args)` with piped stdin/stdout and inherited stderr. This supports pickers that draw on stderr or their controlling terminal while keeping stdout dedicated to the result. The plugin does not capture picker stderr or modify picker-specific environment defaults.
5. Call `Child:write_all(input)`, then `Child:flush()`. The flush is required because Yazi's child stdin is buffered. `Child:wait_with_output()` closes stdin before waiting and draining stdout, so the picker receives EOF without waiting for Lua garbage collection. See the upstream [Child implementation](https://github.com/sxyazi/yazi/blob/main/yazi-binding/src/process/child.rs).
6. Inspect status before interpreting stdout. `1`/`130` cancel even if an early exit caused a broken pipe. Any other nonzero/missing/inconsistent status is an error. A successful status with a failed write/flush remains an error, never a partial-input selection.
7. Remove at most one stdout line terminator. Empty output means no selection; additional lines, NUL/CR, invalid UTF-8, or non-member paths are protocol errors. Check `fs.cha(Url(target), true)` and require a directory, preserving the exact raw supplied path.
8. Release the permit, then report errors or emit `ya.emit("cd", { target, raw = true, tab = job.tab })`. `raw` prevents shell-like expansion by Yazi and the tab ID preserves the invoking destination.

Buffering query output permits inspecting query status before presenting any candidates, keeps query failures separate from picker cancellation, and avoids coupling two concurrent child lifetimes. Memory use grows with history size. There is no candidate count limit, subprocess shell, temporary file, runtime cross-package dependency, or arbitrary interaction timeout.

The supported picker protocol produces only a path on stdout and consumes piped input through EOF before selection. A nonconforming process that writes unbounded stdout before consuming stdin can block the pipe; arbitrary processes and hung pickers are outside this protocol's guarantee.

## Lifecycle and failure handling

The invocation's protected call encompasses configuration, query, hide, spawn, input writes, flush, output/status read, and path validation. A phase string identifies the failing operation in notifications; launch diagnostics identify installation, `PATH`, or configuration actions. Query stderr is included in query failure notifications, while the picker's own stderr is visible in the terminal.

The child and UI permit are owned by the outer invocation scope. On an exception with an owned child, cleanup attempts `start_kill` and `wait` under independent protected calls; an error in either cannot skip permit release. `wait_with_output` consumes the child on ordinary completion, so cleanup does not attempt to reuse a consumed handle. The permit is dropped explicitly rather than relying on garbage collection. Notifications and navigation occur afterward. If the underlying permit-drop API itself fails, report that failure and do not navigate; the plugin cannot guarantee recovery from failure of Yazi's restoration primitive.

Success, cancellation, and ordinary process failures return through the same permit-release path. Configuration/query failures and empty history happen before any UI change. No navigation is attempted on invalid paths, malformed output, unsuccessful status, or incomplete stdin delivery. An emission exception is also reported after restoration.

## Security and compatibility

The executable and argv are trusted local user configuration. They are passed directly as structured process arguments; characters such as spaces, semicolons, and shell metacharacters are not interpreted by the plugin. Candidate paths are data on stdin, not command fragments. A configured executable is still responsible for its own behavior; this is not a sandbox for an untrusted picker.

Selections must exactly match a supplied path and pass a directory metadata check. Membership validation catches decorations, query echoes, accidental path conversion, and unexpected output without inventing picker-specific parsers. Embedded CR/LF names cannot be encoded unambiguously and are unsupported; invalid UTF-8 paths are unsupported. Filesystem races remain possible after validation.

No picker-specific flags or environment overrides appear in runtime code. Inherited defaults can change a picker's behavior and must be checked by the user. Windows-native Yazi uses native Windows tools and history; WSL Yazi uses Linux tools and history. No paths are translated. The independent built-in Zoxide `update_db` subscription continues to receive `cd` events; this package adds no duplicate history subscription.

Yazi Terminal hosts ordinary Windows Yazi, so a matching native tool/configuration may be usable, but terminal rendering, ConPTY, keys, IME and focus are not guaranteed. Live testing belongs to the user and is not a maintainer implementation gate.

## Impact review

| Area | Assessment |
| --- | --- |
| Implementation and callers | New self-contained package; setup and the example uppercase `Z` binding are its only public entry points. Existing plugin implementations are unchanged. |
| Types, DTOs, validation, serialization | New validated Lua setup table and newline input/single-path output protocol. No external DTO or persisted format changes. |
| APIs, routing, permissions, error handling | Current Yazi tab/process APIs, directory metadata checks, and error notifications. No network API, route, or authorization change. |
| Configuration, environment, defaults, migration | Explicit `init.lua` command/argv; no default or migration. Environment is inherited. Zoxide history setup stays separate. |
| Database, files, caches, persistence | Reads through Zoxide's CLI; no plugin database/cache/file writes. Existing Zoxide's own query/database behavior is retained. |
| UI, state, events, accessibility | External TUI hide/restore permit and invoking-tab `cd`; actual picker accessibility, layout, keys, IME, and focus require user checks. No responsive web UI. |
| Translations, messages, logs, monitoring | English notifications and docs. No translation catalog, telemetry, metric, or monitoring changes. |
| Tests, mocks, fixtures, snapshots | New in-memory process/UI/path mocks and aggregate registration; no live E2E or external fixture dependency. |
| Scripts, build, packaging, CI/CD | Package layout and Lua test aggregation only; no dependency/build/workflow changes. No configured formatter, linter, or type checker exists in this repository; Lua parsing and whitespace checks complement the mocks. |
| README, specifications, samples, comments | New package README/license, requirements/design, and init/keymap examples; root README lists the package and states its separate verification boundary. |
| Security, privacy, input, secrets | Direct argv avoids shell injection; strict output validation. No secrets, personal paths, authentication, or collected data are introduced. |
| Backward compatibility, data, existing users | Additive opt-in package; no existing keymap/config is edited automatically. Requires current tab APIs; does not inherit older plugin compatibility claims. Existing history collection remains user-managed. |

## Automated verification and remaining checks

`tests/zoxide-picker/test_main.lua` loads separate setup and async module instances to exercise main-context state access. Mocks record executable/argv, pipe modes, ordered UTF-8 input, flush/EOF sequence, metadata calls, permit drops, cleanup calls, notifications, and emitted tab IDs. Exception injection covers process and cleanup paths; cancellation tests ensure stdout cannot trigger navigation on non-success statuses.

Run from the repository root:

```sh
lua tests/run.lua
git diff --check
luac -p zoxide-picker.yazi/main.lua tests/zoxide-picker/test_main.lua tests/run.lua examples/zoxide-picker/init.lua
```

These are mock, syntax, and whitespace checks only. All actual package installation, executable resolution, picker filtering/matching, terminal display/input, IME/focus, Windows/WSL and Yazi Terminal compatibility remain user-side live checks, as described in the package README. No remote CI or live compatibility result is implied.
