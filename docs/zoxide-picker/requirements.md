# Zoxide picker requirements

This is the specification for [Issue #6](https://github.com/hironei/yazi_plugins/issues/6). User setup, the external process protocol, and troubleshooting are documented in the self-contained [package README](../../zoxide-picker.yazi/README.md); implementation decisions are in [design.md](design.md).

## Goal and scope

Provide `zoxide-picker.yazi`, a generic replacement for the uppercase `Z` directory picker. Users select an external executable and literal argv through Yazi's native `setup` mechanism. The package supplies Zoxide history without coupling runtime code to a particular picker, introducing a shell pipeline, or modifying another repository.

The install unit contains `main.lua`, `README.md`, and `LICENSE`, with no runtime dependency outside the package. Repository examples live in `examples/zoxide-picker/`; mock tests live in `tests/zoxide-picker/` and run through `tests/run.lua`.

## Required behavior

| ID | Requirement |
| --- | --- |
| R1 | `require("zoxide-picker"):setup { command = ..., args = {...} }` selects exactly one executable and its argv. `command` must be a nonempty executable name/path; `args` must be an explicit consecutive array of strings, including an empty array when needed. Reject NUL bytes, invalid types, gaps, and named argv keys. Invalid/missing configuration must produce a clear invocation error without launching any process or selecting a default. |
| R2 | Pass the executable and each argument directly through Yazi's `Command` API. Do not parse shell command strings, invoke a shell function, run Zoxide's interactive mode, or add implicit picker-specific flags or fallbacks. Switching a conforming picker requires only editing `init.lua` and restarting Yazi. |
| R3 | Run `zoxide query --list --exclude <invoking-directory>`. Preserve the returned frecency order. Send UTF-8 LF-delimited records over picker stdin and deliver EOF after flushing. Successful empty history must leave the UI unchanged and start no picker. Failed queries must be diagnosed, including database and missing-tool errors. |
| R4 | Treat picker stdout as a protocol channel: one supplied raw directory path, optionally terminated by one LF or CRLF. Empty successful output means no selection. Reject extra records, decorations, malformed UTF-8, NUL bytes, and paths outside the supplied candidates. Inherit stderr for terminal UI/diagnostics. |
| R5 | Navigate only on status `0` with successful status metadata and one valid existing directory, following directory symlinks. Status `1`/`130` must cancel quietly regardless of stdout; unexpected/missing statuses, malformed output, nonexistent paths, regular files, and launch/read/write failures must notify and never navigate. Early cancellation may close stdin and is still cancellation. |
| R6 | Hide Yazi only for the interactive process and release the UI permit on success, cancellation, empty successful output, errors, and thrown process/metadata exceptions. Stop/reap an owned child on an exception before returning the UI permit. Report notifications and emit navigation after restoring Yazi. |
| R7 | Support Yazi 26.9.1 and later. When `job.tab` exists, read `cx.tab.current.cwd` and use `job.tab` as the destination; a missing modern context is an error. When `job.tab` is absent, capture `cx.active.current.cwd` and `cx.active.id` together through `ya.sync` before querying, then use that exact ID for tab-targeted `cd` after restoring the UI. Missing context or ID must fail before querying. The legacy snapshot uses the then-active tab because old entry jobs carry no invoking identity; later tab changes must not redirect navigation. A removed tab is left to Yazi to handle. |
| R8 | Preserve spaces, Unicode, native Windows paths and Linux/WSL paths without shell quoting or cross-platform path conversion. Document the UTF-8 and newline framing limits, including ambiguity for embedded LF/CR in directory names. |
| R9 | Keep Zoxide history collection independent through the user's existing `require("zoxide"):setup { update_db = true }`. Change only the example uppercase `Z` keymap, leaving unrelated keys, other picker integrations, and the Zoxide database/ranking algorithm independent. |
| R10 | Supply English installation, setup, protocol, limitations, troubleshooting, and user verification instructions, with mutually exclusive illustrative sgs/Yuru configurations. Do not promise binary or terminal-host compatibility based on mocks. |

## Validation and acceptance

The maintainer implementation gate is local, automated mock verification:

- Run `lua tests/run.lua`; existing plugin suites and the new suite must pass.
- Cover invalid/missing setup, setup state crossing the async runtime, literal executable/argv (including executable paths with spaces), configuration-only replacement, and ordered stdin bytes with Unicode/spaces.
- Assert pipe modes, write/flush/EOF sequencing, captured-tab `cd` with `raw = true`, and navigation after permit release. Cover modern precedence, legacy nil/empty jobs and non-string tab IDs, and missing context/ID failures before querying.
- Cover status `0`, `1`, `130`, unexpected/signal/missing statuses, empty output/history, extra lines, invalid UTF-8/NULs, mismatched candidates, stale directories, and files.
- Cover query errors, missing picker errors, constructor/spawn/write/flush/wait/metadata exceptions, hide errors, and cleanup calls. Verify no navigation and balanced permit acquisition/release.
- Run `git diff --check`, inspect changed/untracked files, and syntax-check Lua where available.

These tests establish only mocked behavior. Installation/PATH resolution, actual ordering and filtering inside the chosen picker, picker-specific flags/defaults, performance, Japanese/romaji matching, TUI keys, IME, terminal restoration, display, focus, Windows/WSL behavior, and Yazi Terminal behavior are delegated to the user. Live checks are not an implementation gate and must remain explicitly unverified unless performed.

## Limits and exclusions

- No changes to companion shell/settings repositories, unrelated Issues/keymaps, or terminal host code.
- No new settings format, bundled binary, picker-specific runtime branch, automatic fallback, implicit flag/environment overrides, or dependency update.
- No change to Zoxide history subscription or ranking; no direct database editing.
- No embedded-newline/non-UTF-8 path support, alternate output protocol, multi-selection, or path conversion.
- No guarantee for arbitrary commands or hosts. Adapters for other protocols belong to the user or a separately scoped enhancement.
- No fixed interaction timeout or candidate cap; an unresponsive external picker can require interruption and full history is buffered in memory.
- Filesystem validation is a point-in-time check, and Yazi must still handle a directory disappearing before `cd` executes.
- No commits, pushes, PR creation, or remote CI execution as part of implementation.
