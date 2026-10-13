# zoxide-picker.yazi

Jump to a directory from Zoxide history with an external picker configured in Yazi's `init.lua`. The package has no default picker and no automatic fallback. Changing the executable and arguments requires only a configuration change and a Yazi restart.

## Requirements and installation

- A Yazi build exposing the current tab-scoped plugin APIs: `cx.tab`, `job.tab`, `ya.emit(..., { tab = ... })`, `ya.sync`, `ui.hide`, and the `Command`/`Child` APIs described below. The current upstream Zoxide plugin uses these tab APIs; this package does not inherit the older packages' Yazi 26.8.15/26.9.1 compatibility claims. An older build without these APIs needs an upgrade.
- Matching `ya` package manager.
- `zoxide` in the environment inherited by Yazi.
- A configured external picker that follows the protocol below. Runtime compatibility with any particular binary is the user's responsibility.

```sh
ya pkg add hironei/yazi_plugins:zoxide-picker
```

Add to Yazi's `keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on = "Z"
run = "plugin zoxide-picker"
desc = "Jump to a visited directory using configured picker"
```

Add to `init.lua`, preserving your existing Zoxide history setup:

```lua
-- Keep this existing setup; do not add a second copy if already configured.
require("zoxide"):setup { update_db = true }

require("zoxide-picker"):setup {
    command = "sgs",
    args = { "--no-sort", "--exit-0" },
}
```

Alternatively, replace the picker setup block with this illustrative Yuru configuration:

```lua
require("zoxide-picker"):setup {
    command = "yuru",
    args = { "--no-sort", "--exit-0", "--lang", "ja" },
}
```

Choose exactly one picker block. Verify that your installed [SagasuFinder](https://github.com/hironei/sagasu-finder), [Yuru](https://github.com/Ameyanagi/yuru), or other picker accepts your flags and follows the protocol. These examples are not live compatibility guarantees.

`command` must be a nonempty executable name resolved through `PATH` or an executable path. Do not include flags or shell quoting in it. For a Windows path with spaces, use `command = [[C:\Program Files\Picker\selector.exe]]`. `args` is required and must be a consecutive array of literal strings; use `args = {}` for no arguments. Missing or invalid setup reports a configuration error when invoked and starts no process. `setup` also returns `(false, error_message)` for invalid configuration.

Only the configured executable and argv are used. The plugin adds no picker-specific flags and inherits the user's environment; ensure picker defaults/environment options do not change ordering, delimiters, or output format. For a command that needs a different protocol, configure a user-supplied adapter executable that follows this contract.

## Process protocol and navigation

1. The plugin runs `zoxide query --list --exclude <invoking-directory>` directly. It retains Zoxide's frecency order and does not call the interactive Zoxide command, a shell function, or a shell pipeline.
2. If history is empty, it leaves Yazi visible and launches no picker. Otherwise it hides Yazi, starts the configured executable with the configured argv, and supplies the paths on piped stdin as UTF-8 records separated by LF. It flushes the input before `Child:wait_with_output()` closes stdin, delivering EOF.
3. The picker must preserve input order when filtering (configure its equivalent of `--no-sort` yourself). It must write exactly one supplied raw path to stdout, optionally followed by one LF or CRLF. Spaces, Unicode, native slashes, and drive letters are preserved. Scores, decorations, multiple selections, query echoes, NUL separators, and stdout diagnostics are invalid.
4. Picker stdout is piped; stderr is inherited so a picker may draw its UI or diagnostics there, or open its controlling terminal. It must accept piped stdin/stdout and obtain interactive input from the terminal. The plugin does not capture picker stderr into its notification.
5. Status `0` with a nonempty, well-formed supplied path triggers a filesystem check. Only an existing directory (including a resolved directory symlink) is accepted. After restoring Yazi, the plugin emits `cd` with `raw = true` and the invoking `job.tab`, even if another tab became active during the picker.
6. Status `1` or `130`, or empty successful output, cancels navigation quietly. All other statuses, invalid output, missing tools, launch/read/write failures, and missing directories produce an error notification and no navigation. A directory can still disappear after validation; Yazi handles that final filesystem race.

The newline protocol cannot represent directory names containing embedded LF or CR, and does not support non-UTF-8 paths. Such history is unsupported: LF-containing names may be indistinguishable from multiple records. The invoking directory is rejected if it contains CR/LF. Candidate lists are buffered in memory; there is no plugin-imposed count or byte limit. Extremely large history and external processes that hang are outside the mock verification boundary; no timeout is imposed on user interaction.

The plugin replaces picker navigation only. Keep `require("zoxide"):setup { update_db = true }` to collect history from directory changes. Unrelated `z`/other keymaps and Zoxide's ranking algorithm remain independently configured.

## Platforms and troubleshooting

Use tools and paths from the same environment as Yazi. Windows `yazi.exe` needs Windows executables and Windows history paths, including when launched from Git Bash or Yazi Terminal. WSL Yazi needs Linux executables and Linux history paths. The plugin performs no Windows/WSL path conversion.

- Configuration error: supply one executable and an argv array in `init.lua`, then restart Yazi.
- Cannot query Zoxide: check `zoxide` in Yazi's inherited `PATH` and database access. An unsuccessful query is an error; a successful empty list is a normal empty-history result.
- Cannot launch the picker: check `setup.command`, installation, executable permissions, and inherited `PATH`. Pass an executable path as one string without shell quotes.
- Unexpected status or malformed output: check picker-specific flags/defaults and ensure stdout contains only one selected path. Picker diagnostics appear in the terminal while Yazi is hidden.
- Missing directory: history may be stale or a directory may have disappeared during selection; choose an existing directory.
- Wrong display, key input, IME, or focus: verify your picker in the actual terminal host. Arbitrary picker and terminal combinations are not guaranteed.

## Verification responsibility

Maintainer verification consists of Lua mocks for configuration, process construction, ordered bytes, status handling, path checks, tab targeting, and UI permit cleanup. It does not establish live package installation, TUI operation, or binary compatibility.

Users must verify their installed picker and options in their actual environment:

1. Install the package, configure one picker, keep Zoxide history updates enabled, and restart Yazi.
2. Visit several existing directories (including spaces and Japanese names). Press `Z`, check initial and filtered order, select one, and confirm the invoking tab navigates.
3. Check empty history/no match, Escape/Ctrl-C, invalid output or missing tools, and stale directories. Confirm no unwanted navigation and that Yazi remains usable.
4. Check the picker's keys, Japanese/romaji matching if supported, IME, display, terminal restoration, and window focus.
5. Repeat separately under Windows/Git Bash, WSL, or Yazi Terminal as applicable. Yazi Terminal hosts ordinary Windows Yazi, so the configuration may be usable with native tools, but compatibility is not guaranteed and live verification is not a maintainer implementation gate.

No live sgs, Yuru, regular Yazi, WSL, or Yazi Terminal checks are claimed by this implementation.

## License

MIT. See [LICENSE](LICENSE). External tools are installed separately under their own licenses.
